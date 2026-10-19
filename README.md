# Finovera

Finovera is an intelligent investment recommendation platform combining a Machine Learning pipeline, a robust FastAPI backend, a Streamlit dashboard, and a modern iOS SwiftUI application.

## Architecture

- **Machine Learning Pipeline**: Retrieves financial data, enriches it with macro-economic indicators and news sentiment (Vader Sentiment), and runs recommendation models (Random Forest / XGBoost).
- **Backend**: A FastAPI server handling recommendation logic, serving the ML models, and providing REST endpoints for the frontend applications.
- **Dashboard**: A Streamlit application for data exploration, model training evaluation (using robust temporal out-of-sample chronological validation for 100% leak-free metrics), and administrative tasks.
- **iOS App**: A native SwiftUI application for end-users to receive personalized investment recommendations based on their risk profile, featuring dynamic portfolio allocation driven in real-time by the selected target capital and tracked user tickers.

## Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jbouniol/finovera.git
   cd finovera
   ```

2. **Environment Variables**:
   Create a `.env` file at the root of the project with your API keys (see `.env.example`):
   ```env
   NEWS_API_KEY=your_news_api_key_here
   FRED_API_KEY=your_fred_api_key_here
   ```

3. **Backend Setup**:
   ```bash
   pip install -r app/finovera/Backend/requirements.txt
   cd app/finovera/Backend
   uvicorn app:app --reload
   ```

4. **iOS App Setup**:
   Open `app/finovera/finovera.xcodeproj` in Xcode, ensure you are targeting a simulator or your device, and hit **Run**.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
