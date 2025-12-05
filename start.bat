@echo off

pushd "%~dp0"

set REQUIRE_INSTALL=0
if "%1"=="--install" set REQUIRE_INSTALL=1

if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
        set "%%a=%%b"
    )
)

if not exist "%TEMP_DIRECTORY%" mkdir "%TEMP_DIRECTORY%"
if not exist "%APP_DATA_DIRECTORY%" mkdir "%APP_DATA_DIRECTORY%"

:: Set up Python virtual environment
if %REQUIRE_INSTALL%==1 (
    rmdir /s /q servers\fastapi\.venv
    python -m venv servers\fastapi\.venv
)

if not exist "servers\fastapi\.venv" (
    python -m venv servers\fastapi\.venv
)

call servers\fastapi\.venv\Scripts\activate.bat

if %REQUIRE_INSTALL%==1 (
    :: Install root project dependencies
    call npm ci

    :: Install dependencies for FastAPI
    python -m pip install --upgrade pip setuptools wheel
    pip install aiohttp aiomysql aiosqlite asyncpg fastapi[standard] ^
        pathvalidate pdfplumber chromadb sqlmodel ^
        anthropic google-genai openai fastmcp dirtyjson
    pip install docling --extra-index-url https://download.pytorch.org/whl/cpu

    :: Install dependencies for Next.js
    call npm install --prefix servers\nextjs
    call npm --prefix servers\nextjs run build
)

echo Starting Presenton...
node start.js