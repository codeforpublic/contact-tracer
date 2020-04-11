import AsyncStorage from '@react-native-community/async-storage';

export async function setUserId(userId) {
  try {
    await AsyncStorage.setItem('userId', userId);
  } catch (e) {
    // saving error
  }
}

export async function getUserId() {
  try {
    const value = await AsyncStorage.getItem('userId');
    if (value !== null) {
      return value;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}
