import { StyleSheet } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';

// react-native-maps has no web implementation.
export default function MapScreen() {
  return (
    <ThemedView style={styles.container}>
      <ThemedText type="subtitle">Map</ThemedText>
      <ThemedText themeColor="textSecondary">The map is available on iOS and Android.</ThemedText>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
});
