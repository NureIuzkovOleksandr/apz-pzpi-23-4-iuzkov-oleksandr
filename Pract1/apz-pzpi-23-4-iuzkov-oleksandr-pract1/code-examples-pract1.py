"""
Патерн проєктування «Стратегія» (Strategy)
Приклад реалізації для задач науки про дані (Data Science)
Студент: Юзков Олександр, ПЗПІ-23-4
"""

from abc import ABC, abstractmethod
import math


# ============================================================
# 1. Абстрактна стратегія
# ============================================================

class ModelStrategy(ABC):
    """Абстрактний клас стратегії навчання моделі."""

    @abstractmethod
    def train(self, X: list, y: list) -> dict:
        """Навчає модель на вхідних даних."""
        pass

    @abstractmethod
    def predict(self, model: dict, X: list) -> list:
        """Повертає передбачення для вхідних даних."""
        pass

    @abstractmethod
    def name(self) -> str:
        """Повертає назву алгоритму."""
        pass


# ============================================================
# 2. Конкретні стратегії
# ============================================================

class LinearRegressionStrategy(ModelStrategy):
    """Стратегія: лінійна регресія (метод найменших квадратів)."""

    def train(self, X: list, y: list) -> dict:
        n = len(X)
        sum_x = sum(X)
        sum_y = sum(y)
        sum_xy = sum(X[i] * y[i] for i in range(n))
        sum_xx = sum(X[i] ** 2 for i in range(n))

        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x ** 2)
        intercept = (sum_y - slope * sum_x) / n

        return {"slope": slope, "intercept": intercept}

    def predict(self, model: dict, X: list) -> list:
        return [model["slope"] * x + model["intercept"] for x in X]

    def name(self) -> str:
        return "Лінійна регресія"


class KNNStrategy(ModelStrategy):
    """Стратегія: метод k найближчих сусідів (k-NN)."""

    def __init__(self, k: int = 3):
        self.k = k

    def train(self, X: list, y: list) -> dict:
        # k-NN зберігає навчальні дані як модель
        return {"X_train": X, "y_train": y}

    def predict(self, model: dict, X: list) -> list:
        predictions = []
        for x in X:
            distances = [
                (abs(x - x_train), y_train)
                for x_train, y_train in zip(model["X_train"], model["y_train"])
            ]
            distances.sort(key=lambda d: d[0])
            k_nearest = [d[1] for d in distances[: self.k]]
            predictions.append(sum(k_nearest) / len(k_nearest))
        return predictions

    def name(self) -> str:
        return f"k-NN (k={self.k})"


class DecisionStumpStrategy(ModelStrategy):
    """Стратегія: одноступеневе дерево рішень (Decision Stump)."""

    def train(self, X: list, y: list) -> dict:
        best_threshold = None
        best_error = float("inf")

        for threshold in X:
            predictions = [
                sum(yi for xi, yi in zip(X, y) if xi <= threshold)
                / max(1, sum(1 for xi in X if xi <= threshold))
                if sum(1 for xi in X if xi <= threshold) > 0
                else 0
                for _ in [threshold]
            ]
            left_mean = (
                sum(yi for xi, yi in zip(X, y) if xi <= threshold)
                / max(1, sum(1 for xi in X if xi <= threshold))
            )
            right_mean = (
                sum(yi for xi, yi in zip(X, y) if xi > threshold)
                / max(1, sum(1 for xi in X if xi > threshold))
            )
            error = sum(
                (yi - (left_mean if xi <= threshold else right_mean)) ** 2
                for xi, yi in zip(X, y)
            )
            if error < best_error:
                best_error = error
                best_threshold = threshold
                best_left = left_mean
                best_right = right_mean

        return {
            "threshold": best_threshold,
            "left_value": best_left,
            "right_value": best_right,
        }

    def predict(self, model: dict, X: list) -> list:
        return [
            model["left_value"] if x <= model["threshold"] else model["right_value"]
            for x in X
        ]

    def name(self) -> str:
        return "Дерево рішень (Stump)"


# ============================================================
# 3. Контекст — конвеєр машинного навчання
# ============================================================

class MLPipeline:
    """
    Контекст, який використовує стратегію навчання.
    Дозволяє замінювати алгоритм без зміни коду конвеєра.
    """

    def __init__(self, strategy: ModelStrategy):
        self._strategy = strategy
        self._model = None

    def set_strategy(self, strategy: ModelStrategy) -> None:
        """Замінює поточну стратегію навчання."""
        self._strategy = strategy
        self._model = None
        print(f"  Стратегію змінено на: {strategy.name()}")

    def fit(self, X: list, y: list) -> None:
        """Навчає модель із поточною стратегією."""
        print(f"  Навчання за алгоритмом: {self._strategy.name()}")
        self._model = self._strategy.train(X, y)

    def predict(self, X: list) -> list:
        """Повертає передбачення."""
        if self._model is None:
            raise RuntimeError("Модель ще не навчена. Спочатку викличте fit().")
        return self._strategy.predict(self._model, X)

    def evaluate(self, X: list, y_true: list) -> float:
        """Обчислює середньоквадратичну похибку (RMSE)."""
        y_pred = self.predict(X)
        mse = sum((yt - yp) ** 2 for yt, yp in zip(y_true, y_pred)) / len(y_true)
        return math.sqrt(mse)


# ============================================================
# 4. Демонстрація використання
# ============================================================

def main():
    # Навчальні дані: залежність між кількістю годин навчання та оцінкою
    X_train = [1, 2, 3, 4, 5, 6, 7, 8]
    y_train = [50, 55, 60, 65, 70, 75, 80, 85]
    X_test = [3, 6, 9]
    y_test = [60, 75, 90]

    print("=" * 55)
    print("Демонстрація патерну «Стратегія» у задачі регресії")
    print("=" * 55)

    # Створення конвеєра з початковою стратегією
    pipeline = MLPipeline(LinearRegressionStrategy())

    strategies = [
        LinearRegressionStrategy(),
        KNNStrategy(k=2),
        DecisionStumpStrategy(),
    ]

    for strategy in strategies:
        print(f"\n--- {strategy.name()} ---")
        pipeline.set_strategy(strategy)
        pipeline.fit(X_train, y_train)
        predictions = pipeline.predict(X_test)
        rmse = pipeline.evaluate(X_test, y_test)
        print(f"  Передбачення для {X_test}: {[round(p, 2) for p in predictions]}")
        print(f"  RMSE: {rmse:.4f}")

    print("\n" + "=" * 55)
    print("Висновок: стратегію змінено тричі без зміни коду конвеєра.")
    print("=" * 55)


if __name__ == "__main__":
    main()
