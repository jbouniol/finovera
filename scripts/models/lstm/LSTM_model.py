import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import train_test_split



# === CONFIGURATION ===
SEED = 42
BATCH_SIZE = 64
EPOCHS = 20
LEARNING_RATE = 1e-3
HIDDEN_SIZE = 64
IS_CLASSIFICATION = True  # False = regression

# === 1. CHARGEMENT DES DONNÉES ===
data = np.load("data/sequences_lstm.npz")
X = data["X"]  # shape (n_seq, window_size, n_features)
y = data["y"]   # shape (n_seq,)


print("X shape:", X.shape)
print("X max:", np.max(X))
print("X min:", np.min(X))
print("Any NaN in X:", np.isnan(X).any())
print("y unique values:", np.unique(y))
print("Any NaN in y:", np.isnan(y).any())

# === 2. SPLIT TRAIN/TEST ===
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=SEED, stratify=y if IS_CLASSIFICATION else None)

X_train_tensor = torch.tensor(X_train, dtype=torch.float32)
X_test_tensor = torch.tensor(X_test, dtype=torch.float32)
y_train_tensor = torch.tensor(y_train, dtype=torch.long if IS_CLASSIFICATION else torch.float32)
y_test_tensor = torch.tensor(y_test, dtype=torch.long if IS_CLASSIFICATION else torch.float32)

train_ds = TensorDataset(X_train_tensor, y_train_tensor)
test_ds = TensorDataset(X_test_tensor, y_test_tensor)

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True)
test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE)

# === 3. MODÈLE LSTM ===
class LSTMModel(nn.Module):
    def __init__(self, input_size, hidden_size, is_classification):
        super().__init__()
        self.lstm = nn.LSTM(input_size=input_size, hidden_size=hidden_size, batch_first=True)
        self.fc = nn.Linear(hidden_size, 2 if is_classification else 1)
        self.is_classification = is_classification

    def forward(self, x):
        _, (h_n, _) = self.lstm(x)
        out = self.fc(h_n[-1])
        return out

if __name__ == "__main__":
    model = LSTMModel(input_size=X.shape[2], hidden_size=HIDDEN_SIZE, is_classification=IS_CLASSIFICATION)
    criterion = nn.CrossEntropyLoss() if IS_CLASSIFICATION else nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)

    for epoch in range(EPOCHS):
        model.train()
        train_loss = 0
        for X_batch, y_batch in train_loader:
            optimizer.zero_grad()
            outputs = model(X_batch)
            loss = criterion(outputs, y_batch if IS_CLASSIFICATION else y_batch.unsqueeze(1))
            loss.backward()
            optimizer.step()
            train_loss += loss.item()
        print(f"\u2705 Epoch {epoch+1}/{EPOCHS} - Loss: {train_loss / len(train_loader):.4f}")

    # === 4. ÉVALUATION SIMPLE ===
    model.eval()
    correct, total = 0, 0
    with torch.no_grad():
        for X_batch, y_batch in test_loader:
            outputs = model(X_batch)
            if IS_CLASSIFICATION:
                preds = torch.argmax(outputs, dim=1)
                correct += (preds == y_batch).sum().item()
                total += y_batch.size(0)
            else:
                mse = nn.functional.mse_loss(outputs.squeeze(), y_batch)
                print(f"MSE sur test : {mse.item():.4f}")
                break

    if IS_CLASSIFICATION:
        print(f"\n\u2b50 Accuracy sur test : {correct / total:.4f}")
    # Sauvegarde du modèle
    torch.save(model.state_dict(), "data/lstm_model.pt")
    print("💾 Modèle LSTM sauvegardé dans data/lstm_model.pt")
        
    
  

    
    



