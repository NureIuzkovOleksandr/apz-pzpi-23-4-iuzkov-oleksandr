from locust import HttpUser, task, between, events
import requests

SHARED_TOKEN = None

@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    global SHARED_TOKEN
    host = environment.host
    print(f"Logging in to {host} to fetch a shared token...")
    try:
        resp = requests.post(f"{host}/api/auth/login", json={"email": "admin@example.com", "password": "admin1234"}, timeout=15)
        if resp.status_code == 200:
            SHARED_TOKEN = resp.json().get("access_token")
            print("Shared token successfully fetched!")
        else:
            print(f"Login failed with status {resp.status_code}: {resp.text}")
    except Exception as e:
        print(f"Error during login: {e}")

class APIUser(HttpUser):
    wait_time = between(0.0, 0.0)

    def on_start(self):
        global SHARED_TOKEN
        if SHARED_TOKEN:
            self.client.headers.update({"Authorization": f"Bearer {SHARED_TOKEN}"})

    @task(4)
    def cpu_load(self):
        """CPU-bound work — main stress task"""
        self.client.post("/api/test/load?intensity=6&duration_seconds=2", name="/api/test/load")

    @task(2)
    def health_check(self):
        self.client.get("/health")

    @task(1)
    def metrics(self):
        self.client.get("/metrics")
