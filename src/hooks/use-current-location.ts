import * as Location from 'expo-location';
import { useEffect, useState } from 'react';

type State = {
  location: Location.LocationObject | null;
  error: string | null;
};

export function useCurrentLocation(): State {
  const [state, setState] = useState<State>({ location: null, error: null });

  useEffect(() => {
    let cancelled = false;

    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        if (!cancelled) setState({ location: null, error: 'Location permission denied' });
        return;
      }
      try {
        const location = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });
        if (!cancelled) setState({ location, error: null });
      } catch (e) {
        if (!cancelled) setState({ location: null, error: (e as Error).message });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  return state;
}
