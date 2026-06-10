# NerdleBundle

### Application Concept
NerdleBundle is a curated collection of DLE-type games (distinct from idle games, which are an entirely different concept), inspired by New York Times mini-games like Connections and Wordle. This bundle brings together various trivia games that all revolve around gaming and movie themes. Each game within the collection stands out with its unique approach, ensuring the gameplay remains engaging without becoming overly complex. The aim is to create an enjoyable experience that captures attention without being overwhelming or distracting.

We all have moments when we need to unwind- whether it's while brewing a cup of morning coffee, preparing for school, or commuting to work. Although catching up on the morning news can spark interesting conversations, it can also be overwhelming. If the news is grim, it can cast a shadow over the whole day. Diving into a mobile game or lengthy media just isn't feasible for many people either. That's where NerdleBundle comes in; it offers quick games that only take moments to play, allowing you to rack up your score and get back to your day without missing a beat.

Here is  the outline of some of the key features that can be accessed through the application:

**Account Management**
>To fully experience all the amazing features the app has to offer, users are encouraged to create an account. While registration is optional, signing up with an email, username, and password is essential in order for users to join the leaderboard and showcase their skills.


**Leaderboard**
>Users will receive a score based on their performance, which can be posted on a leaderboard if they choose to. This leaderboard will feature two tabs: one for the daily rankings and another for the weekly or all-time standings, depending on how well the Firebase real-time syncing works (I’m not very familiar with that aspect just yet). If users achieve high scores, it is anticipated that it will positively enhance their overall experience throughout the day.


**Statistics**
>In conjunction with the leaderboard upload feature, players will have the opportunity to view their ranking relative to other participants. This will include a message indicating their performance percentile, such as "You perform better than 60% of other players," along with a corresponding graphical representation to illustrate their standing effectively. This feature is more of a "why not?" addition designed to provide players with instant feedback, making it easier to track their progress in trivia and enhancing accessibility.


**Film Connections**
>The core gameplay loop involves players being presented with two randomly chosen movies. Once they hit the start button, a timer kicks off, and they'll see a list of actors from the first movie. Players then select one actor, which brings up a list of all the movies they've appeared in. The challenge continues as players choose a movie and connect it to the second selected film. The goal is to achieve the shortest connection possible while minimising the time taken, as both factors contribute to the final score.
>
>For instance, imagine you click on the Film Connections button from the main menu. A screen pops up featuring two films: the original Star Wars and Rush Hour. After clicking start, the timer begins ticking in the top left corner, and a list of actors from Star Wars appears. You browse through the names and select James Earl Jones, the original voice of Darth Vader, known for his roles as a narrator in numerous films from the early 2000s to the 2010s. You then access a list of all the movies he's been part of and spot Rogue One: A Star Wars Story. 
>
>From there, you remember that one of the leading actors in Rogue One is Donnie Yen, who played a villain in Shanghai Knights, starring Owen Wilson and Jackie Chan. Notably, Jackie Chan also stars in Rush Hour, your second movie. You make the final connection, resulting in a distance of three with a timer reading 1 minute and 30 seconds. A pop-up then appears, presenting the shortest possible connection: Star Wars → Mark Hamill (Luke Skywalker) (1) → Star Wars: The Force Awakens (the Disney film) → Ken Leung (the villain in Rush Hour) (2) → Rush Hour. Not the best result, but hey, you are still in the top twenty per cent of the best players; keep it up, and you will be the best in no time.


**Guess the Price: Steam games edition**
>The user will receive five randomly selected video games, each accompanied by its poster or cover image, the top three screenshots, and the respective game genre. These games will be presented one at a time. Subsequently, the user will have five attempts to estimate the price of each game in Australian dollars (AUD). The API call will be structured in such a manner that the games are not listed as being on sale, thereby ensuring that the displayed price accurately reflects the game's standard value. The user's score will be determined based on the number of attempts taken to correctly guess each price.



***

### Competition and Innovation
The target audience for the application consists of individuals who possess an interest in trivia games, as well as those who seek a means of relaxation while remaining engaged with familiar and appealing subjects, specifically movies and video games. If I were to develop a user persona for this demographic, it would predominantly include men in their late twenties to early thirties, who may be single or in a relationship without children. These individuals are typically employed and derive enjoyment from various forms of media consumption, including watching films and playing video games. 

The application is designed to serve as a recreational outlet, providing users with an opportunity to alleviate stress during commutes or to cultivate the right mindset before starting a demanding workday.

Many people, including potential users, have experienced the thrill of New York Times DLE games at least once in their lives. However, there comes a time when the excitement fades and the games feel repetitive. This is where fresh trivia concepts shine, especially those rich in theme and style. NerdleBundle encapsulates this ethos through its distinctive offerings and dynamic approach, rendering it genuinely worth giving a shot.



***

### Interface Design and Navigation
**Storyboard:**

<img width="1378" height="706" alt="Storyboard" src="https://github.com/user-attachments/assets/fdd82003-bcbe-4ac7-9afc-befe0edf27f5" />


Figma Prototype link:
(https://www.figma.com/proto/s4G1fo391obyOGae8m2lqs/FIT3178_A1_VadimFilyakin_33764506?node-id=2-2&t=H8YGelsO73VxW0xE-1)

Sidenote: The transitions and interactions have been integrated into the Figma board, covering most functionalities and capturing the essence of the core user interactions.


Here is the hierarchy of pages for the app:


* Home Page
* * Buttons to redirect to the actual trivia games
* * Navbar
* * * A link to the account management page
* * * A link to the settings tab
* * * A link to the Leaderboard
* Leaderboard
* * Daily Leaderboard
* * Weekly/All-time Leaderboard
* * A list of users with their respective point count
* Account Management Page
* * Login page
* * * Contains fields for email and password
* * * Has a redirection link to the Register page
* * Register page
* * * Utilises email, username, and password fields
* * Account Summary
* * * Contains some related analytics and is accompanied by a visual representation
* * * Has an option to change the user's avatar
* Settings page
* * A toggle to switch between light mode and dark mode
* * An option to tweak the text size for the whole application (Accessibility features)
* * Contact us redirection
* Movie Connections (Trivia 1)
* * A timer
* * Posters for the two initial movies
* * List of related movies/cast members
* * An outline of how the user performed by the end of it
* Steamdle (Guess the Price; Trivia 2)
* * A cover/poster for the video game
* * The top three screenshots from the Steam library for the game
* * Input fields for the users to put their guesses into
* * Visual representation of how close/away the user's guess was


***

### Interface Design and Navigation Justification
The design adheres to the HIGs, as it was designed around the concept of accessibility rather than the other way around. It has a navigation bar at the bottom of the screen at all times; there are “go back” buttons present whenever the user gets more than one layer deep into a certain tab. The colour scheme is designed around contrasting colours (the most classy ones of such, even that being dark grey and white for the main part, and crimson red for the highlights. Even though according to some popular belief, red colour has rage-inducing effect on a lot of people, some also associate it with cinema due to the colour of the seats in dome theatres, so it was ultimately decided to cater to that audience instead), and all the buttons and interactable elements have highlights. 

The app also follows Accessibility, namely adaptability, value of HIGs pretty closely, which is evident by the existence of light mode/ dark mode toggle and the text size toggle. All the icons used in the Figma are either the default ones from the Apple toolkit or just some obscurely bent vectors, created by me (except for the screw icon, I took that one from the New York Times template). 

The only real concern I have regarding the HIGs is that I don’t, unfortunately, believe the app is going to be secure, since I was planning on using Firebase for the database management, which is notorious for having minimal security measures employed.



***

### Feasibility and Technology
External API’s:

* https://www.themoviedb.org)https://www.themoviedb.org/ - TMDB contains a lot of info on TV shows, as well as movies and every other sort of cinematic media, really. I am planning on using it for the Film Connections trivia game as a backbone to get all the initial data and automate the process of actually making the trivia itself.
* https://steamcommunity.com/dev)https://steamcommunity.com/dev - Steam as a platform has its own video game database, so I am aiming to use it for Steamdle, a game where you guess the price of a video game.


As a part of the requirements, I will also be using:

* Persistent storage for the progress in the current trivia
* Web services are to be used in pretty much every step of the app, except for the settings page, I’d presume
* Firebase to store the vast majority of the data. I’ll also attempt to turn it into a real-time database, and sync some of the functionalities with the server time, but I have yet to read on whether it’s even possible to achieve this using Firebase without me spending any more of my money on it
* Swift Charts (Could-have), I might use it to make some visual representation of the data the users will be getting once they are done with the trivia (e.g., “You are better than 80% of the other players”, and then show the data in charts of how much they scored compared to the user)
* Local Notifications (Could-have), if the Firebase part goes well, but the Charts part doesn’t, then I’d probably just make a notification feature for whenever a new day starts and the trivia gets updated



***
### Scope and Estimate Project Timeline


<meta charset="utf-8"><b style="font-weight:normal;" id="docs-internal-guid-1ba8723e-7fff-e4d2-bf72-8adccae4b630"><div dir="ltr" style="margin-left:0pt;" align="left">
  | Description | Priority (MoSCoW) | To be done by the end of week_
-- | -- | -- | --
1 | Initial Setup, Persistent storage setup, and develop some frontend templates for the pages | Must-have | 6
2 | Make the Steamdle (guess the price game), without any point system implemented just yet | Must-have | 7
3 | Implement Firebase, the point system, and the account management features (login/sign up) | Must-have | 8
4 | Develop Local notifications/ Swift Charts | Could-have | 9
5 | Design and implement the Movie Connections trivia game | Should-have | 10

</div><br /></b>
