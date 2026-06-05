# Organizer iOS App

An iOS productivity app for managing events and routines with recurring schedules, built using Swift, SwiftUI, and SwiftData. The app focuses on structured daily planning with support for repeating events, weekly routines, and notifications.

## Overview

The app provides two primary planning systems:

- **Events**: Date-based items that can repeat on configurable intervals and are displayed in a chronological list.
- **Routines**: Weekly recurring items assigned to specific days of the week, managed separately in their own tab.

The main view combines both systems to present a unified daily overview, mixing events and routines relevant to the selected day.
Sorting by time of day or priority is available in the main view. Sorting by day is presented in the Routines view.

## Screenshots

![App screenshot](Screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-05-01%20at%2013.20.33.png)

## Core Features

### Event Management
- Create events with deadlines and optional recurrence rules
- View events in a structured list
- Duplicate existing events for faster setup
- Edit events indestructively
- Batch deletion and completion support

### Routine Management
- Define routines assigned to specific weekdays
- Automatically repeat routines weekly
- Manage routines in a dedicated tab
- Duplicate, delete, edit routines
- Batch complete and delete supported

### Daily Overview
- Combined view of:
  - Scheduled events for a selected day
  - Routines occurring on that weekday
- Provides a complete snapshot of the user’s day
- Allows sorting by time of day or priority, as well as hiding Routines for a cleaner view

### Notifications
- Schedule notifications before event deadlines
- Centralized notification handling via `NotificationManager`
- Rich notification content

### Platform Features
- Dark mode support
- Icon tinting
- Full localization support (English and Bulgarian)
- Intuitive taptic feedback for all user interactions

## Technology Stack

- Swift
- SwiftUI
- SwiftData

## App Architecture

The app follows a typical SwiftUI + MVVM structure:

- **Models** define persistent data (SwiftData-backed)
- **ViewModels** manage transformation and app logic
- **Views** render UI and bind to observable state
- **Notification layer** operates independently for scheduling reminders

## Goals

- Provide a structured yet flexible personal planning system
- Combine recurring routines with flexible event scheduling
- Reduce friction in daily planning via automation and duplication tools
- Maintain a lightweight, fully native iOS architecture
