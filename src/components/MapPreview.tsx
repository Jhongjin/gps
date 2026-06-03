import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import type { Member } from '../data/mock';
import { colors, radii } from '../theme/tokens';

type Props = {
  members: Member[];
};

export function MapPreview({ members }: Props) {
  return (
    <View accessibilityLabel="서클 지도 미리보기" style={styles.map}>
      <View style={styles.grid} />
      <View style={[styles.water, styles.waterOne]} />
      <View style={[styles.park, styles.parkOne]} />
      <View style={[styles.road, styles.roadOne]} />
      <View style={[styles.road, styles.roadTwo]} />
      <View style={[styles.road, styles.roadThree]} />
      <Text style={[styles.district, styles.homeLabel]}>집</Text>
      <Text style={[styles.district, styles.schoolLabel]}>학원</Text>
      <Text style={[styles.district, styles.clinicLabel]}>병원</Text>
      {members.map((member) => (
        <React.Fragment key={member.id}>
          {member.precision !== 'exact' ? (
            <View style={[styles.accuracy, { left: `${member.x}%`, top: `${member.y}%` }]} />
          ) : null}
          <View
            style={[
              styles.marker,
              member.status === 'moving' && styles.movingMarker,
              member.status === 'alert' && styles.alertMarker,
              { left: `${member.x}%`, top: `${member.y}%` },
            ]}
          >
            <Text style={styles.markerText}>{member.name.slice(0, 1)}</Text>
          </View>
        </React.Fragment>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  map: {
    aspectRatio: 1.08,
    backgroundColor: colors.mapGround,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    overflow: 'hidden',
    position: 'relative',
  },
  grid: {
    ...StyleSheet.absoluteFillObject,
    opacity: 0.16,
  },
  water: {
    backgroundColor: colors.mapWater,
    position: 'absolute',
  },
  waterOne: {
    borderRadius: 120,
    height: 150,
    right: -35,
    top: -15,
    width: 170,
  },
  park: {
    backgroundColor: colors.mapPark,
    position: 'absolute',
  },
  parkOne: {
    borderRadius: 80,
    bottom: -28,
    height: 135,
    left: -30,
    width: 170,
  },
  road: {
    backgroundColor: colors.mapRoad,
    borderRadius: 8,
    height: 16,
    left: -20,
    position: 'absolute',
    width: '120%',
  },
  roadOne: {
    top: '30%',
    transform: [{ rotate: '-16deg' }],
  },
  roadTwo: {
    top: '56%',
    transform: [{ rotate: '22deg' }],
  },
  roadThree: {
    height: 12,
    top: '74%',
    transform: [{ rotate: '-5deg' }],
  },
  district: {
    color: 'rgba(21, 28, 25, 0.42)',
    fontSize: 11,
    fontWeight: '900',
    position: 'absolute',
  },
  homeLabel: {
    left: '10%',
    top: '18%',
  },
  schoolLabel: {
    left: '62%',
    top: '19%',
  },
  clinicLabel: {
    left: '46%',
    top: '70%',
  },
  accuracy: {
    backgroundColor: 'rgba(49, 95, 140, 0.13)',
    borderColor: 'rgba(49, 95, 140, 0.45)',
    borderRadius: 48,
    borderStyle: 'dashed',
    borderWidth: 1,
    height: 96,
    marginLeft: -48,
    marginTop: -48,
    position: 'absolute',
    width: 96,
  },
  marker: {
    alignItems: 'center',
    backgroundColor: colors.primary,
    borderColor: colors.surface,
    borderRadius: 18,
    borderWidth: 3,
    height: 36,
    justifyContent: 'center',
    marginLeft: -18,
    marginTop: -18,
    position: 'absolute',
    width: 36,
  },
  movingMarker: {
    backgroundColor: colors.blue,
  },
  alertMarker: {
    backgroundColor: colors.danger,
  },
  markerText: {
    color: colors.surface,
    fontSize: 14,
    fontWeight: '900',
  },
});
