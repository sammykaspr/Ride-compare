from ..schemas import Recommendations, RideOption


def best_picks(options: list[RideOption]) -> Recommendations:
    if not options:
        return Recommendations()

    cheapest = min(options, key=lambda o: o.price_min)
    fastest = min(options, key=lambda o: o.eta_minutes)

    prices = [o.price_min for o in options]
    etas = [o.eta_minutes for o in options]
    p_min, p_max = min(prices), max(prices)
    e_min, e_max = min(etas), max(etas)

    def score(o: RideOption) -> float:
        p_norm = (o.price_min - p_min) / (p_max - p_min) if p_max > p_min else 0.0
        e_norm = (o.eta_minutes - e_min) / (e_max - e_min) if e_max > e_min else 0.0
        return p_norm + e_norm

    best_value = min(options, key=score)

    return Recommendations(
        cheapest=cheapest.ride_type_id,
        fastest=fastest.ride_type_id,
        best_value=best_value.ride_type_id,
    )
