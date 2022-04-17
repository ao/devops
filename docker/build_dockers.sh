# build frontend
docker build -t mock_frontend_python frontend/
docker tag mock_frontend_python:latest aoms/mock_frontend_python:latest
docker push aoms/mock_frontend_python:latest

# build backend
docker build -t mock_backend_python backend/
docker tag mock_backend_python:latest aoms/mock_backend_python:latest
docker push aoms/mock_backend_python:latest
