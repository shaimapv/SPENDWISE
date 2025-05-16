# SPENDWISE - Smart Savings Predictor App

**SpendWise** is a mobile application built using **Flutter** that helps users **predict their savings** by analyzing past financial expenses. The app leverages machine learning to make intelligent predictions and helps users understand their spending behavior.


##  What It Does

- **Predicts savings** based on user-entered financial expenses
- Uses an **Artificial Neural Network (ANN)** model to make predictions
- Backend is built with **FastAPI** for serving the ML model
- Financial data and predictions are stored in **Firebase Firestore**
- Previously stored data is reused for continuous training of the model

##  Installation & Setup
### Prerequisites

Ensure you have the following installed on your system:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Python 3.7 or higher
- pip (Python package manager)
- Firebase CLI (optional, for hosting or emulator)


## Machine Learning Model

SpendWise uses an **Artificial Neural Network (ANN)** model to predict a user's savings based on their past financial expenses.
