import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import joblib
import numpy as np
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.regularizers import l2
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# Suppress TensorFlow warnings


# Initialize Firebase
cred_path = os.path.join(r"C:\coding\backend\python1", "spendwise2-firebase-adminsdk-fbsvc-c9ed53401c.json")

cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

# Feature columns
features = ["monthly_income", "financial_aid", "tuition", "housing", "food",
            "transportation", "books_supplies", "entertainment", "personal_care"]
target = ["miscellaneous"]


app = FastAPI()

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins - restrict in production!
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


def train_model():
    print("Fetching training data from Firestore...")
    docs = db.collection("training_data").stream()
    data = [doc.to_dict() for doc in docs]
    df = pd.DataFrame(data)

    if df.empty:
        raise ValueError("No training data found in Firestore")
    
    df.dropna(inplace=True)
    
    global X_scaler, y_scaler
    X_scaler = MinMaxScaler()
    y_scaler = MinMaxScaler()
    df[features] = X_scaler.fit_transform(df[features])
    df[target] = y_scaler.fit_transform(df[target])
    
    joblib.dump(X_scaler, "X_scaler.pkl")
    joblib.dump(y_scaler, "y_scaler.pkl")
    
    X_train = df[features].values
    y_train = df[target].values

    model = Sequential([
        Dense(9, activation='relu', kernel_regularizer=l2(0.001)),
        Dropout(0.2),
        Dense(256, activation='relu', kernel_regularizer=l2(0.001)),
        Dropout(0.2),
        Dense(64, activation='relu', kernel_regularizer=l2(0.001)),
        Dense(1, activation='linear')
    ])
    
    optimizer = Adam(learning_rate=0.001)
    model.compile(optimizer=optimizer, loss='mse', metrics=['mae'])

    early_stopping = EarlyStopping(monitor='loss', patience=5, restore_best_weights=True)
    reduce_lr = ReduceLROnPlateau(monitor='loss', factor=0.5, patience=3, min_lr=1e-5)
    
    model.fit(X_train, y_train, epochs=50, batch_size=32, callbacks=[early_stopping, reduce_lr], verbose=1)
    model.save("expense_prediction_model.keras")
    print("Model training complete. Model saved.")

def load_resources():
    global model, X_scaler, y_scaler
    if not os.path.exists("expense_prediction_model.keras"):
        train_model()
    model = load_model("expense_prediction_model.keras")
    X_scaler = joblib.load("X_scaler.pkl")
    y_scaler = joblib.load("y_scaler.pkl")
    print("Model and scalers loaded.")

load_resources()

class ExpenseData(BaseModel):
    monthly_income: float
    financial_aid: float
    tuition: float
    housing: float
    food: float
    transportation: float
    books_supplies: float
    entertainment: float
    personal_care: float

@app.get("/")
async def root():
    return {"message": "Welcome to the Expense Prediction API!"}

@app.post("/predict")
async def predict_expense(expense: ExpenseData):
    try:
        input_data = pd.DataFrame([[
            expense.monthly_income, expense.financial_aid, expense.tuition, expense.housing,
            expense.food, expense.transportation, expense.books_supplies, expense.entertainment,
            expense.personal_care
        ]], columns=features)
        
        user_scaled = X_scaler.transform(input_data)
        predicted_expense = model.predict(user_scaled)
        predicted_expense_original = float(y_scaler.inverse_transform(predicted_expense)[0][0])
        return {"predicted_miscellaneous": round(predicted_expense_original, 2)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# @app.post("/test")
# async def test_model(file: UploadFile = File(...)):
#     try:
#         student_df = pd.read_csv(file.file)
#         student_df.columns = student_df.columns.str.strip()
        
#         if not set(features).issubset(student_df.columns):
#             raise ValueError("Test dataset does not contain the required features")
        
#         student_df.dropna(inplace=True)
#         student_scaled = X_scaler.transform(student_df[features])
#         predicted_expense_scaled = model.predict(student_scaled)
#         predicted_expense_original = y_scaler.inverse_transform(predicted_expense_scaled)

#         y_student_test = student_df[target].values
#         y_student_pred = predicted_expense_original.flatten()

#         from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
#         mse_student = mean_squared_error(y_student_test, y_student_pred)
#         mae_student = mean_absolute_error(y_student_test, y_student_pred)
#         rmse_student = np.sqrt(mse_student)
#         r2_student = r2_score(y_student_test, y_student_pred)

#         return {
#             "mae": round(mae_student, 4),
#             "mse": round(mse_student, 4),
#             "rmse": round(rmse_student, 4),
#             "r2_score": round(r2_student, 4)
#         }
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
@app.post("/test")
async def test_model():
    try:
        # Define the fixed path to your test file
        TEST_JSON_PATH = "csvjson.json"  # Assuming it's in the same directory
        
        # Verify the file exists
        if not os.path.exists(TEST_JSON_PATH):
            raise HTTPException(
                status_code=400,
                detail=f"Test file not found at path: {TEST_JSON_PATH}"
            )
        
        # Load JSON file
        with open(TEST_JSON_PATH, 'r') as f:
            data = json.load(f)
        student_df = pd.DataFrame(data)
        
        # Clean and validate data
        student_df.columns = student_df.columns.str.strip()
        
        if not set(features).issubset(student_df.columns):
            missing = set(features) - set(student_df.columns)
            raise ValueError(f"Test dataset is missing required features: {missing}")
        
        student_df.dropna(inplace=True)
        
        if len(student_df) == 0:
            raise ValueError("No valid data remaining after dropping rows with missing values")
        
        # Make predictions
        student_scaled = X_scaler.transform(student_df[features])
        predicted_expense_scaled = model.predict(student_scaled)
        predicted_expense_original = y_scaler.inverse_transform(predicted_expense_scaled)

        # Calculate metrics
        y_student_test = student_df[target].values
        y_student_pred = predicted_expense_original.flatten()
        
        mse_student = mean_squared_error(y_student_test, y_student_pred)
        mae_student = mean_absolute_error(y_student_test, y_student_pred)
        rmse_student = np.sqrt(mse_student)
        r2_student = r2_score(y_student_test, y_student_pred)

        return {
            "mae": round(mae_student, 4),
            "mse": round(mse_student, 4),
            "rmse": round(rmse_student, 4),
            "r2_score": round(r2_student, 4),
            "data_source": f"Used local test file: {TEST_JSON_PATH}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
