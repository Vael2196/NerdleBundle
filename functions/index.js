import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import axios from "axios";

initializeApp();

const db = getFirestore();
const TMDB_ACCESS_TOKEN = defineSecret("TMDB_ACCESS_TOKEN");
// const TMDB_API_KEY = defineSecret("TMDB_API_KEY");

const MEL_TZ = "Australia/Melbourne";

// In-memory caches so TMDB isn’t spammed for the same actors/movies repeatedly
const movieCastCache = new Map();
const personMoviesCache = new Map();

/**
 * Tiny helper that returns a preconfigured TMDB axios client.
 * Token is pulled from Cloud Functions secret at runtime.
 */
function tmdb() {
  const token = TMDB_ACCESS_TOKEN.value();
  return axios.create({
    baseURL: "https://api.themoviedb.org/3",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json;charset=utf-8",
    },
    timeout: 10000,
  });
}

/**
 * Firestore trigger:
 * Whenever a new fc_daily/{dayId} doc is created,
 * this function makes sure the movie pair and shortest path are filled in.
 */
export const fcDailyOnCreate = onDocumentCreated(
    {
      document: "fc_daily/{dayId}",
      region: "australia-southeast2",
      secrets: [TMDB_ACCESS_TOKEN],
      retry: false,
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      if (!data) return;
      try {
        // If the doc has no movies yet, generate a new pair + path
        if (!data.movieA || !data.movieB) {
          console.log("fcDailyOnCreate: picking pair for", snap.id);
          // const picked = await pickGoodPair(5, 12);
          const picked = await pickConnectedPair();
          if (!picked) {
            await snap.ref.update({
              status: "pending",
              errorMessage: "no_pair_found",
              computedAt: FieldValue.serverTimestamp(),
            });
            return;
          }
          const { movieA, movieB, path, distance } = picked;
          await snap.ref.update({
            movieA,
            movieB,
            shortestPath: path,
            shortestDistance: distance,
            status: "ready",
            computedAt: FieldValue.serverTimestamp(),
          });
          return;
        }

        // If movies exist but shortestDistance is missing, backfill it
        if (data.shortestDistance == null) {
          const { path, distance } = await findShortestConnection(data.movieA.id, data.movieB.id);
          await snap.ref.update({
            shortestPath: path,
            shortestDistance: distance,
            status: "ready",
            computedAt: FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        console.error("fcDailyOnCreate failed:", e);
        await snap.ref.update({
          status: "error",
          errorMessage: (e && e.message) ? e.message : String(e),
          computedAt: FieldValue.serverTimestamp(),
        });
      }
    },
);

/**
 * Fetches a page of “discover” movies from TMDB,
 * sorted by popularity and filtered to not be cursed.
 */
async function discoverPopularMovies(page = 1) {
  const { data } = await tmdb().get("/discover/movie", {
    params: {
      "sort_by": "popularity.desc",
      "vote_count.gte": 100,
      "include_adult": false,
      page,
    },
  });
  return data.results || [];
}

/**
 * cast fetcher for BFS:
 * returns top 8 actors (id + name) and caches the result.
 */
async function getMovieCredits(movieId) {
  if (movieCastCache.has(movieId)) return movieCastCache.get(movieId);
  const { data } = await tmdb().get(`/movie/${movieId}/credits`);
  const cast = (data.cast || [])
      .slice(0, 8)
      .map((c) => ({ id: c.id, name: c.name }));
  movieCastCache.set(movieId, cast);
  return cast;
}

/**
 * “actor -> movies” fetcher for BFS:
 * returns up to 12 popular movies per person and caches the result.
 */
async function getPersonMovieCredits(personId) {
  if (personMoviesCache.has(personId)) return personMoviesCache.get(personId);
  const { data } = await tmdb().get(`/person/${personId}/movie_credits`);
  const movies = (data.cast || [])
      .sort((a, b) => (b.popularity || 0) - (a.popularity || 0))
      .slice(0, 12)
      .map((m) => ({
        id: m.id,
        title: m.title || m.original_title || "",
        posterPath: m.poster_path || null,
        releaseDate: m.release_date || null,
      }));
  personMoviesCache.set(personId, movies);
  return movies;
}

/**
 * Fetches basic info for a single movie (used to seed paths).
 */
async function getMovieInfo(movieId) {
  const { data } = await tmdb().get(`/movie/${movieId}`);
  return {
    id: data.id,
    title: data.title || data.original_title || "",
    posterPath: data.poster_path || null,
    releaseDate: data.release_date || null,
  };
}

/**
 * Full cast fetch for the client (FilmConnections cast view).
 */
async function getMovieCreditsFull(movieId) {
  const { data } = await tmdb().get(`/movie/${movieId}/credits`);
  return (data.cast || []).map((c) => ({
    id: c.id,
    name: c.name,
    profilePath: c.profile_path || null,
  }));
}

/**
 * Full movie list for an actor, sorted by popularity.
 * Used by the client when exploring all movies for an actor.
 */
async function getPersonMovieCreditsFull(personId) {
  const { data } = await tmdb().get(`/person/${personId}/movie_credits`);
  return (data.cast || [])
      .sort((a, b) => (b.popularity || 0) - (a.popularity || 0))
      .map((m) => ({
        id: m.id,
        title: m.title || m.original_title || "",
        posterPath: m.poster_path || null,
        releaseDate: m.release_date || null,
      }));
}

/** 
 * Legacy “random pair + BFS” picker has been left commented out for reference.
 * It was replaced because it sometimes took too long or failed to find a path.
*/
// async function pickGoodPair(maxDistance = 5, maxAttempts = 12) {
//   let best = null;
//   const start = Date.now();
//   for (let attempt = 0; attempt < maxAttempts; attempt++) {
//     const page = Math.floor(Math.random() * 20) + 1;
//     const results = await discoverPopularMovies(page);
//     if (!results || results.length < 2) continue;

//     const i = Math.floor(Math.random() * results.length);
//     let j = Math.floor(Math.random() * results.length);
//     if (j === i) j = (j + 1) % results.length;

//     const a = results[i];
//     const b = results[j];
//     const movieA = {
//       id: a.id,
//       title: a.title || a.original_title || "",
//       posterPath: a.poster_path || null,
//       releaseDate: a.release_date || null,
//     };
//     const movieB = {
//       id: b.id,
//       title: b.title || b.original_title || "",
//       posterPath: b.poster_path || null,
//       releaseDate: b.release_date || null,
//     };

//     const { path, distance } = await findShortestConnection(movieA.id, movieB.id);
//     if (distance > -1 && distance <= maxDistance) {
//       return { movieA, movieB, path, distance };
//     }
//     if (distance > -1 && (!best || distance < best.distance)) {
//       best = { movieA, movieB, path, distance };
//     }
//     if (Date.now() - start > 50_000) break;
//   }
//   return best;
// }

/**
 * Builds a guaranteed-connected chain between two movies:
 *  - start from a random popular movie
 *  - randomly walk Movie -> Actor -> Movie without reusing nodes
 *  - chain length is 2-5 actor hops
 *  - then tries BFS to see if a shorter connection exists
 */
async function pickConnectedPair() {
  const depth = Math.floor(Math.random() * 4) + 2; // 2–5
  console.log(`Building random chain of depth ${depth}`);

  // Grab a random popular movie as the starting point
  const page = Math.floor(Math.random() * 5) + 1;
  const popular = await discoverPopularMovies(page);
  const start = popular[Math.floor(Math.random() * popular.length)];
  const movieA = {
    id: start.id,
    title: start.title || start.original_title || "",
    posterPath: start.poster_path || null,
    releaseDate: start.release_date || null,
  };

  // Path is stored as alternating movie/person nodes
  const chain = [{ type: "movie", ...movieA }];
  const usedMovies = new Set([movieA.id]);
  const usedPeople = new Set();

  let currentMovie = movieA;

  for (let step = 0; step < depth; step++) {
    // Pick a new actor who hasn't been used yet
    const cast = await getMovieCredits(currentMovie.id);
    const availableActors = cast.filter((a) => !usedPeople.has(a.id));
    if (!availableActors.length) break;

    const actor = availableActors[Math.floor(Math.random() * availableActors.length)];
    usedPeople.add(actor.id);
    chain.push({ type: "person", id: actor.id, name: actor.name });

    // From that actor, pick a new movie that hasn't been used yet
    const movies = await getPersonMovieCredits(actor.id);
    const nextCandidates = movies.filter((m) => !usedMovies.has(m.id));
    if (!nextCandidates.length) break;

    const next = nextCandidates[Math.floor(Math.random() * nextCandidates.length)];
    usedMovies.add(next.id);
    const movieNode = {
      type: "movie",
      id: next.id,
      title: next.title,
      posterPath: next.posterPath,
      releaseDate: next.releaseDate,
    };
    chain.push(movieNode);
    currentMovie = movieNode;
  }

  const movieB = chain[chain.length - 1];
  console.log(`Generated connected pair: ${movieA.title} ↔ ${movieB.title}`);

  // Fallback path is the randomly built chain
  let finalPath = chain;
  let distance = chain.filter((n) => n.type === "person").length;
  // BFS is used to see if a shorter connection exists.
  // If BFS fails or gives a longer path, the original chain is kept.
  try {
    const { path, distance: d } = await findShortestConnection(movieA.id, movieB.id);
    if (path.length && d < distance) {
      finalPath = path;
      distance = d;
    }
  } catch (err) {
    console.warn("BFS failed, using fallback chain:", err.message);
  }

  return { movieA, movieB, path: finalPath, distance };
}


// Alternate by layers: Movie -> Person -> Movie -> Person and so on
// The "distance" is set to be a number of Person (actor) hops in the path.
/**
 * BFS over the movie–person graph.
 * Starts at movie A and alternates movie→person→movie layers until B is hit,
 * or MAX_DEPTH is reached.
 */
async function findShortestConnection(movieIdA, movieIdB) {
  if (movieIdA === movieIdB) {
    const info = await getMovieInfo(movieIdA);
    return { path: [{ type: "movie", ...info }], distance: 0 };
  }

  const visitedMovies = new Set([movieIdA]);
  const visitedPeople = new Set();

  const startMovie = await getMovieInfo(movieIdA);
  const targetMovieId = movieIdB;
  const queue = [[{ type: "movie", ...startMovie }]];

  const MAX_DEPTH = 6;

  while (queue.length) {
    const path = queue.shift();
    if (path.length > MAX_DEPTH) continue;

    const last = path[path.length - 1];

    if (last.type === "movie") {
      const cast = await getMovieCredits(last.id);
      for (const p of cast) {
        if (visitedPeople.has(p.id)) continue;
        visitedPeople.add(p.id);

        const newPath = [...path, { type: "person", id: p.id, name: p.name }];
        queue.push(newPath);
      }
    } else {
      const movies = await getPersonMovieCredits(last.id);
      for (const m of movies) {
        if (visitedMovies.has(m.id)) continue;
        visitedMovies.add(m.id);

        const movieNode = { type: "movie", id: m.id, title: m.title, posterPath: m.posterPath, releaseDate: m.releaseDate };
        const newPath = [...path, movieNode];

        if (m.id === targetMovieId) {
          const distance = newPath.filter((n) => n.type === "person").length;
          return { path: newPath, distance };
        }
        queue.push(newPath);
      }
    }
  }

  return { path: [], distance: -1 };
}

/**
 * Returns a yyyy-MM-dd string for “today” in the given timezone.
 * Used as the daily document ID.
 */
function todayIdInTz(tz = MEL_TZ) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(new Date());
  const y = parts.find((p) => p.type === "year").value;
  const m = parts.find((p) => p.type === "month").value;
  const d = parts.find((p) => p.type === "day").value;
  return `${y}-${m}-${d}`;
}

/**
 * Scheduled function (midnight Melbourne):
 * creates today’s FilmConnections pair if it doesn’t already exist.
 * Uses the old “good connected pair” generator.
 */
// export const generateDailyFilmPair = onSchedule(
//     {
//       timeZone: "Australia/Melbourne",
//       schedule: "0 0 * * *",
//       secrets: [TMDB_ACCESS_TOKEN],
//       region: "australia-southeast1",
//       retry: { retryCount: 0 },
//     },
//     async () => {
//       const dayId = todayIdInTz();
//       const docRef = db.collection("fc_daily").doc(dayId);

//       const exists = (await docRef.get()).exists;
//       if (exists) return;
//       const picked = await pickGoodPair(5, 12);
//       if (picked) {
//         const { movieA, movieB, path, distance } = picked;
//         await docRef.set({
//           dayId,
//           date: FieldValue.serverTimestamp(),
//           movieA,
//           movieB,
//           shortestPath: path,
//           shortestDistance: distance,
//           status: "ready",
//           createdAt: FieldValue.serverTimestamp(),
//           source: "tmdb",
//           version: 1,
//         });
//       } else {
//         await docRef.set({
//           dayId,
//           date: FieldValue.serverTimestamp(),
//           movieA: null,
//           movieB: null,
//           shortestPath: [],
//           shortestDistance: null,
//           status: "pending",
//           createdAt: FieldValue.serverTimestamp(),
//           source: "tmdb",
//           version: 1,
//         });
//       }
//     },
// );

/**
 * Scheduled function (midnight Melbourne):
 * creates today’s FilmConnections pair if it doesn’t already exist.
 * Uses the new “guaranteed connected pair” generator.
 */
export const generateDailyFilmPair = onSchedule(
    {
      timeZone: "Australia/Melbourne",
      schedule: "0 0 * * *",
      region: "australia-southeast1",
      secrets: [TMDB_ACCESS_TOKEN],
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async () => {
      const dayId = todayIdInTz();
      const ref = db.collection("fc_daily").doc(dayId);
      if ((await ref.get()).exists) return;

      try {
        const picked = await pickConnectedPair();
        await ref.set({
          dayId,
          date: FieldValue.serverTimestamp(),
          movieA: picked.movieA,
          movieB: picked.movieB,
          shortestPath: picked.path,
          shortestDistance: picked.distance,
          status: "ready",
          createdAt: FieldValue.serverTimestamp(),
          version: 2,
        });
      } catch (e) {
        console.error("generateDailyFilmPair failed:", e);
        await ref.set({
          dayId,
          date: FieldValue.serverTimestamp(),
          status: "error",
          errorMessage: e.message || String(e),
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    },
);

/**
 * HTTPS callable used by the app to fetch today’s FilmConnections payload.
 * If doc doesn’t exist yet, a placeholder “choosing” doc is created.
 */
export const getTodayFilmPair = onCall(
    { secrets: [TMDB_ACCESS_TOKEN], region: "australia-southeast2" },
    async () => {
      console.log("getTodayFilmPair invoked");
      const dayId = todayIdInTz();
      const doc = await db.collection("fc_daily").doc(dayId).get();
      if (!doc.exists) {
        await db.collection("fc_daily").doc(dayId).set({
          dayId,
          date: FieldValue.serverTimestamp(),
          movieA: null,
          movieB: null,
          shortestPath: [],
          shortestDistance: null,
          status: "choosing",
          createdAt: FieldValue.serverTimestamp(),
          source: "tmdb",
          version: 1,
        });
        return {
          dayId,
          date: new Date().toISOString(),
          movieA: null,
          movieB: null,
          shortestPath: [],
          shortestDistance: null,
          status: "choosing",
        };
      } else {
        const data = doc.data() || {};
        const toIso = (ts) =>
            (ts && typeof ts.toDate === "function") ?
              ts.toDate().toISOString() :
              (typeof ts === "string" ? ts : null);
        const payload = {
          dayId,
          date: toIso(data.date),
          movieA: data.movieA ?? null,
          movieB: data.movieB ?? null,
          shortestPath: data.shortestPath ?? [],
          shortestDistance: (data.shortestDistance ?? null),
          status: data.status ?? (data.shortestDistance != null ? "ready" : "pending"),
        };
        console.log("getTodayFilmPair returning existing doc", { dayId, status: payload.status });
        return payload;
      }
    },
);

/**
 * Callable: returns full cast list for a given movie.
 */
export const getMovieCast = onCall(
    { secrets: [TMDB_ACCESS_TOKEN], region: "australia-southeast2" },
    async (req) => {
      const movieId = Number(req.data?.movieId);
      if (!movieId) throw new Error("movieId required");
      const cast = await getMovieCreditsFull(movieId);
      return { cast };
    },
);

/**
 * Callable: returns full movie list for a given person.
 */
export const getPersonMovies = onCall(
    { secrets: [TMDB_ACCESS_TOKEN], region: "australia-southeast2" },
    async (req) => {
      const personId = Number(req.data?.personId);
      if (!personId) throw new Error("personId required");
      const movies = await getPersonMovieCreditsFull(personId);
      return { movies };
    },
);


// !!!!!!!!!!!!!!!!!!!!STEAMDLE FUNCTIONS START HERE!!!!!!!!!!!!!!!!!!!!!

/**
 * Preconfigured axios client for the Steam store API.
 */
function steam() {
  return axios.create({
    baseURL: "https://store.steampowered.com",
    timeout: 10000,
  });
}

/**
 * Pulls “featured” game buckets for the AU store.
 */
async function steamFeaturedAu() {
  const { data } = await steam().get("/api/featuredcategories", {
    params: { cc: "au", l: "en" },
  });
  return data || {};
}

/**
 * Fetches app details for a single Steam appid in AU region.
 */
async function steamAppDetails(appid) {
  const { data } = await steam().get("/api/appdetails", {
    params: { appids: appid, cc: "au", l: "en" },
  });
  const entry = data?.[appid];
  if (!entry || !entry.success) return null;
  return entry.data || null;
}

/**
 * Squishes all the featured buckets into a unique set of appids.
 */
function uniqueIdsFromFeatured(feat) {
  const buckets = [
    feat.top_sellers?.items,
    feat.new_releases?.items,
    feat.specials?.items,
    feat.top_new?.items,
    feat.trending?.items,
    feat.popular_upcoming?.items,
    feat.most_played?.items,
  ].filter(Boolean);

  const set = new Set();
  for (const arr of buckets) {
    for (const it of arr) {
      const id = Number(it.id || it.appid);
      if (Number.isFinite(id)) set.add(id);
    }
  }
  return Array.from(set);
}

/**
 * Standard Fisher–Yates shuffle because vibes.
 */
function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = (Math.random() * (i + 1)) | 0;
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/**
 * Picks 3 Steam games for AU region that:
 *  - are actual games
 *  - are not free
 *  - are priced in AUD
 *  - are not on sale
 *  - have at least some screenshots/metadata
 *
 * Used for the daily Steamdle round.
 */
async function pickThreeSteamAuGames() {
  const feat = await steamFeaturedAu();
  let ids = uniqueIdsFromFeatured(feat);
  if (!ids.length) throw new Error("No featured games to choose from");
  ids = shuffle(ids).slice(0, 80);

  const picked = [];
  for (const id of ids) {
    if (picked.length >= 3) break;
    try {
      const d = await steamAppDetails(id);
      if (!d) continue;
      if (String(d.type).toLowerCase() !== "game") continue;
      if (d.is_free) continue;
      const p = d.price_overview;
      if (!p) continue;
      if (String(p.currency).toUpperCase() !== "AUD") continue;
      if ((p.discount_percent || 0) > 0) continue;

      const priceAUD = (p.final || 0) / 100.0;
      if (priceAUD <= 0) continue;

      const screenshots = (d.screenshots || []).slice(0, 3).map((s) => s.path_full || s.path_thumbnail).filter(Boolean);
      const genres = (d.genres || []).map((g) => g.description).filter(Boolean);

      picked.push({
        appid: Number(d.steam_appid),
        name: d.name || "",
        headerImage: d.header_image || "",
        screenshots,
        genres,
        priceAUD: Math.round(priceAUD * 100) / 100,
      });
    } catch (_) {/* Fuck it we ball. Imma test it in deloyment (Icarus ahh development) */}
  }
  if (picked.length < 3) throw new Error("Failed to pick 3 suitable games");
  return picked;
}

/**
 * Scheduled function (midnight Melbourne):
 * generates today’s Steamdle trio and stores it in steamdle_daily/{dayId}.
 */
export const generateDailySteamdle = onSchedule(
    {
      timeZone: "Australia/Melbourne",
      schedule: "0 0 * * *",
      region: "australia-southeast1",
      retry: { retryCount: 0 },
    },
    async () => {
      const dayId = todayIdInTz();
      const ref = db.collection("steamdle_daily").doc(dayId);
      if ((await ref.get()).exists) return;

      try {
        const games = await pickThreeSteamAuGames();
        await ref.set({
          dayId,
          date: FieldValue.serverTimestamp(),
          games,
          status: "ready",
          createdAt: FieldValue.serverTimestamp(),
          source: "steam",
          version: 1,
        });
      } catch (e) {
        await ref.set({
          dayId,
          date: FieldValue.serverTimestamp(),
          games: [],
          status: "error",
          errorMessage: (e && e.message) ? e.message : String(e),
          createdAt: FieldValue.serverTimestamp(),
          source: "steam",
          version: 1,
        });
      }
    },
);

/**
 * Callable used by the app to fetch today’s Steamdle games.
 * If today’s doc doesn’t exist, it lazily tries to generate one.
 */
export const getTodaySteamdle = onCall(
    { region: "australia-southeast2" },
    async () => {
      const dayId = todayIdInTz();
      const ref = db.collection("steamdle_daily").doc(dayId);
      const snap = await ref.get();

      if (!snap.exists) {
        try {
          const games = await pickThreeSteamAuGames();
          await ref.set({
            dayId,
            date: FieldValue.serverTimestamp(),
            games,
            status: "ready",
            createdAt: FieldValue.serverTimestamp(),
            source: "steam",
            version: 1,
          });
          return { dayId, status: "ready", games };
        } catch {
          await ref.set({
            dayId,
            date: FieldValue.serverTimestamp(),
            games: [],
            status: "choosing",
            createdAt: FieldValue.serverTimestamp(),
            source: "steam",
            version: 1,
          });
          return { dayId, status: "choosing", games: [] };
        }
      }

      const data = snap.data() || {};
      return {
        dayId,
        status: data.status ?? (Array.isArray(data.games) && data.games.length === 3 ? "ready" : "pending"),
        games: data.games ?? [],
      };
    },
);
