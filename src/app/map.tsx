import { StyleSheet } from 'react-native';
import MapView, { Marker } from 'react-native-maps';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Spacing } from '@/constants/theme';
import { useCurrentLocation } from '@/hooks/use-current-location';

// Centered on Puerto Rico.
const INITIAL_REGION = {
  latitude: 18.2208,
  longitude: -66.5901,
  latitudeDelta: 1.6,
  longitudeDelta: 1.6,
};

export default function MapScreen() {
  const { location, error } = useCurrentLocation();

  return (
    <ThemedView style={styles.container}>
      <MapView style={StyleSheet.absoluteFill} initialRegion={INITIAL_REGION} showsUserLocation>
        {location && (
          <Marker
            coordinate={{
              latitude: location.coords.latitude,
              longitude: location.coords.longitude,
            }}
            title="You are here"
          />
        )}
      </MapView>
      {error && (
        <ThemedView type="backgroundElement" style={styles.banner}>
          <ThemedText type="small">{error}</ThemedText>
        </ThemedView>
      )}
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  banner: {
    position: 'absolute',
    top: Spacing.six,
    alignSelf: 'center',
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
    borderRadius: Spacing.two,
  },
});
