import numpy as np  
import seaborn as sns  
import pandas as pd  
import matplotlib.pyplot as plt  
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
from copy import deepcopy 
from scipy import stats
from tabulate import tabulate
from sklearn.preprocessing import LabelEncoder
data = pd.read_csv("spend.csv")
df = deepcopy(data)
print(df.head(10))
del df['Unnamed: 0']
print(df.columns)
print(df.isna().sum())
print(df.duplicated().sum())
numeric_columns = ['age', 'monthly_income', 'financial_aid', 'tuition', 'housing', 'food',
                    'transportation', 'books_supplies', 'entertainment', 'personal_care',
                    'technology', 'health_wellness', 'miscellaneous']
Q1 = df[numeric_columns].quantile(0.25)
Q3 = df[numeric_columns].quantile(0.75)
IQR = Q3 - Q1
outliers_iqr = ((df[numeric_columns] < (Q1 - 1.5 * IQR)) | (df[numeric_columns] > (Q3 + 1.5 * IQR)))
print("\nOutliers (IQR Method):")
print(outliers_iqr.sum())
print("\nNo magical outliers detected")
print(df.info())
for column in df.columns:
    if df[column].dtype == 'object':
        df[column] = df[column].astype('category')
print(df.info())
def column_info_table(df):
    table_df = pd.DataFrame({
        'Column Name': df.columns,
        'Data Type': df.dtypes.values,
        'Number of Unique Values': df.nunique().values,
        'Unique Values': [df[column].unique()[:5] for column in df.columns]
    })
    return table_df
result_table = column_info_table(df)
print(tabulate(result_table, headers='keys', tablefmt='pretty'))
print(df.describe().T )
sns.set(style="whitegrid")
fig, ax = plt.subplots(figsize=(8, 8))
ax.pie(df['gender'].value_counts(), labels=df['gender'].value_counts().index, autopct='%1.2f%%', colors=sns.color_palette('pastel'), startangle=90)
ax.set_title('Distribution of Gender')
plt.show()
sns.set(style="whitegrid")
fig, ax = plt.subplots(figsize=(8, 8))
ax.pie(df['year_in_school'].value_counts(), labels=df['year_in_school'].value_counts().index, autopct='%1.2f%%', colors=sns.color_palette('pastel'), startangle=90)
ax.set_title('Distribution of Year in college')
plt.show()
sns.set(style="whitegrid")
plt.figure(figsize=(8, 8))
ax = sns.countplot(x='major', data=df, palette='viridis')
for p in ax.patches:
    ax.annotate(f'{p.get_height()}', (p.get_x() + p.get_width() / 2., p.get_height()),
                ha='center', va='center', xytext=(0, 10), textcoords='offset points')
plt.title('Distribution of Major')
plt.show()
sns.set(style="whitegrid")
plt.figure(figsize=(8, 8))
ax = sns.countplot(x='preferred_payment_method', data=df, palette='viridis')
for p in ax.patches:
    ax.annotate(f'{p.get_height()}', (p.get_x() + p.get_width() / 2., p.get_height()),
                ha='center', va='center', xytext=(0, 10), textcoords='offset points')
plt.title('Distribution of Payment Method')
plt.show()
selected_columns = ['monthly_income', 'financial_aid', 'tuition', 'housing', 'entertainment', 'transportation']
num_rows = len(selected_columns) // 2 + len(selected_columns) % 2
num_cols = 2
fig, axes = plt.subplots(num_rows, num_cols, figsize=(12, 3 * num_rows))
axes = axes.flatten()
for i, column in enumerate(selected_columns):
    sns.histplot(df[column], bins=20, kde=True, ax=axes[i], color='skyblue')
for rect in axes[i].patches:
        height = rect.get_height()
        axes[i].text(rect.get_x() + rect.get_width() / 2, height, f'{int(height)}', ha='center', va='bottom', fontsize=8)

axes[i].set_title(f'Distribution of {column}')
axes[i].set_xlabel(column)
axes[i].set_ylabel('Frequency')
plt.tight_layout()
plt.show()
selected_columns = ['tuition', 'major', 'year_in_school']
filtered_df = df[selected_columns].dropna()
plt.figure(figsize=(16, 8))
sns.barplot(x='tuition', y='major', hue='year_in_school', data=filtered_df, ci=None, palette='viridis')
plt.title('Tuition Distribution Across Majors and Academic Years')
plt.xlabel('Tuition')
plt.ylabel('Major')
plt.legend(title='Academic Year')
plt.show()
selected_columns = ['preferred_payment_method', 'major', 'year_in_school']
filtered_df = df[selected_columns].dropna()
plt.figure(figsize=(14, 10))
sns.countplot(x='major', hue='preferred_payment_method', data=filtered_df, palette='muted', hue_order=['Cash', 'Credit/Debit Card', 'Mobile Payment App'])
for p in plt.gca().patches:
    plt.gca().annotate(f'{p.get_height()}', (p.get_x() + p.get_width() / 2., p.get_height()),
                       ha='center', va='center', xytext=(0, 10), textcoords='offset points')
plt.title('Preferred Payment Method Distribution Across Majors and Academic Years')
plt.xlabel('Major')
plt.ylabel('Count')
plt.legend(title='Payment Method')
plt.show()
df_copy = df.copy()
label_encoder = LabelEncoder() # Initialize LabelEncoder from scikit-learn
categorical_columns = ['gender', 'year_in_school', 'major', 'preferred_payment_method']
for column in categorical_columns: 
    df_copy[column] = label_encoder.fit_transform(df_copy[column])
correlation_matrix = df_copy.corr()
print(correlation_matrix.iloc[:,-1].sort_values(ascending=False))
plt.figure(figsize=(18, 12))
sns.heatmap(correlation_matrix, cmap='coolwarm', linewidths=0.5 , annot=True)
plt.title('Correlation Heatmap')
plt.show()