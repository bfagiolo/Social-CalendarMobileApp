# Social-CalendarMobileApp

Stamp is a smart social calendar app designed to make event planning effortless, fun, and iconic.
At its core, Stamp uses natural language processing to transform casual text inputs like “Lunch tmrw at 3pm” into fully structured events. I trained and fine-tuned a Flan-T5 Base model on a custom dataset of thousands of curated examples I personally wrote by hand, ensuring the NLP feels natural and reliable in real-world use.

Stamp aims to understand the context of an event beyind just the content. This stems from identifying the category for the event, the predicted user mood surrounding the event, the priority level of the event, and of course its location and time. 

Beyond AI, Stamp is built around design and experience. I created the interface in Figma, translating every concept into reality with Flutter in Android Studio. The app’s branding is anchored by the Stamp animation — whenever a user confirms and publicizes an event, their event card is “stamped,” tying together the mail-themed visual language of inboxes, letters, and shared communication.
Stamp also rethinks collaboration. Group chats are automatically generated around events, powered by careful Firebase Auth + Firestore user ID tracking, making it seamless for friends to coordinate without losing context. This unique integration makes planning not just simple, but genuinely social.

Tech Stack
Frontend: Flutter (Dart),
Backend / AI: Python (Flan-T5 Base, fine-tuned on custom dataset),
Database & Auth: Firebase Firestore + Firebase Authentication,
Design: Figma (from concept to production)

Unlike most social media today, which often keeps people glued to their screens, Stamp was built with the opposite goal: to bring people together in real life. By making it seamless to turn quick thoughts into shared events and automatically connecting the right people in group chats, Stamp encourages face-to-face hangouts instead of isolated scrolling. It’s designed to give younger users a tool that feels social, but ultimately leads them to spend more time with each other, not with the app.

Feel free to watch the demo vids uploaded.

This project is shared for viewing and learning purposes only. All rights are reserved. Please do not copy, reuse, or redistribute the code or the underlying ideas without permission.

I am open to collaboration so those who are interested are more than welcome to reach out. 
Email: Blf67@cornell.edu

https://github.com/user-attachments/assets/4629853a-2f6d-4181-9951-a734ba77875d
<img width="314" height="707" alt="taskinput" src="https://github.com/user-attachments/assets/6fab4d24-b393-4dc5-adaa-8b87554659d8" />

<img width="322" height="712" alt="previewcard" src="https://github.com/user-attachments/assets/0ae41782-eef3-459b-aaf9-67a4127c9d9d" />






