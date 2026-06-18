# Reading Tracker — Architecture Overview

## 1. Core Idea
A macOS Swift app that tracks reading behavior, stores books, and generates analytics + predictions + recommendations.

---

## 2. Main Modules

### Book System
- Imports EPUB/PDF files
- Stores metadata (title, author, length, genre)
- Tracks reading position

### Session System
- Tracks when reading starts/stops
- Measures session duration
- Links sessions to books

### Analytics Engine
- Calculates reading speed
- Tracks completion time
- Builds habit patterns (time of day, streaks, frequency)

### Estimation Engine
- Predicts time to finish books/chapters
- Uses historical reading speed

### Recommendation Engine
- Suggests books based on behavior patterns
- Uses genre + complexity + past engagement

---

## 3. Data Flow

Book Opened
→ Session Started
→ Reading Progress Tracked
→ Session Ends
→ Analytics Updated
→ Predictions Updated
→ Recommendations Updated

---

## 4. Current Risk
- System is growing faster than understanding
- Multiple “engine” files may overlap in responsibility
- Need clearer separation of logic boundaries

---

## 5. Goal
Make the system:
- Modular
- Predictable
- Easy to reason abouts