# Week 1 - Data model

## Core entities

### User

- id: string
- email: string
- passwordHash/password (dev only)
- displayName: string
- role: enum(student, mentor, admin)
- createdAt: datetime
- updatedAt: datetime

### Profile

- userId: string (1-1 User)
- avatarUrl: string?
- bio: string?

## Week 4-5 entities

### Course

- id: string
- title: string
- description: string
- level: enum(beginner, intermediate, advanced)

### Lesson

- id: string
- courseId: string (n-1 Course)
- title: string
- order: int
- content: string (ly thuyet)
- quizId: string? (nullable)

### Quiz

- id: string
- courseId: string
- lessonId: string
- title: string
- questions: Question[]

### Question

- id: string
- prompt: string
- options: string[]
- correctIndex: int (server-side only)
- explanation: string

### QuizAttempt

- attemptId: string
- quizId: string
- userId: string
- score: int
- total: int
- submittedAt: datetime
- answers: map(questionId -> selectedIndex)
- review: list(questionId, selectedIndex, correctIndex, isCorrect, explanation)
