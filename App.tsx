import React, { useMemo, useState } from 'react';
import { SafeAreaView, StatusBar, StyleSheet, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { HomeScreen } from './src/screens/HomeScreen';
import { CircleScreen } from './src/screens/CircleScreen';
import { HistoryScreen } from './src/screens/HistoryScreen';
import { PrivacyScreen } from './src/screens/PrivacyScreen';
import { colors, spacing } from './src/theme/tokens';
import { IconButton } from './src/components/IconButton';

type TabKey = 'map' | 'circle' | 'history' | 'privacy';

const tabs: Array<{ key: TabKey; label: string; icon: keyof typeof MaterialCommunityIcons.glyphMap }> = [
  { key: 'map', label: '지도', icon: 'map-marker-radius-outline' },
  { key: 'circle', label: '서클', icon: 'account-group-outline' },
  { key: 'history', label: '기록', icon: 'timeline-clock-outline' },
  { key: 'privacy', label: '프라이버시', icon: 'shield-check-outline' },
];

export default function App() {
  const [activeTab, setActiveTab] = useState<TabKey>('map');
  const activeScreen = useMemo(() => {
    if (activeTab === 'circle') return <CircleScreen />;
    if (activeTab === 'history') return <HistoryScreen />;
    if (activeTab === 'privacy') return <PrivacyScreen />;
    return <HomeScreen />;
  }, [activeTab]);

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor={colors.canvas} />
      <View style={styles.appShell}>
        <View style={styles.header}>
          <View>
            <View style={styles.brandRow}>
              <Text style={styles.appName}>곁에</Text>
              <Text style={styles.statusChip}>균형 공유</Text>
            </View>
            <Text style={styles.subtitle}>우리 가족 · 마지막 업데이트 1분 전</Text>
          </View>
          <IconButton icon="bell-outline" accessibilityLabel="알림" onPress={() => undefined} />
        </View>
        <View style={styles.content}>{activeScreen}</View>
        <View style={styles.tabBar}>
          {tabs.map((tab) => {
            const isActive = activeTab === tab.key;
            return (
              <IconButton
                key={tab.key}
                icon={tab.icon}
                label={tab.label}
                active={isActive}
                accessibilityLabel={`${tab.label} 탭`}
                onPress={() => setActiveTab(tab.key)}
              />
            );
          })}
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: colors.canvas,
  },
  appShell: {
    flex: 1,
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.md,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  brandRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: spacing.xs,
  },
  appName: {
    color: colors.ink,
    fontSize: 24,
    fontWeight: '900',
    letterSpacing: 0,
  },
  statusChip: {
    backgroundColor: colors.primarySoft,
    borderRadius: 6,
    color: colors.primary,
    fontSize: 11,
    fontWeight: '900',
    overflow: 'hidden',
    paddingHorizontal: spacing.xs,
    paddingVertical: spacing.xxs,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 4,
  },
  content: {
    flex: 1,
  },
  tabBar: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginVertical: spacing.md,
    minHeight: 68,
    paddingHorizontal: spacing.xs,
  },
});
