package com.nuuneoi.lib.contacttracer.utils;

import android.util.Log;

import java.io.Serializable;
import java.util.*;

public final class ParseLeAdvData {
	private final static String TAG = "ParseLeAdvData";

	// =LE �㲥����������
	public static final short BLE_GAP_AD_TYPE_FLAGS = 0x01;
	/** < Flags for discoverability. */
	public static final short BLE_GAP_AD_TYPE_16BIT_SERVICE_UUID_MORE_AVAILABLE = 0x02;
	/** < Partial list of 16 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_16BIT_SERVICE_UUID_COMPLETE = 0x03;
	/** < Complete list of 16 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_32BIT_SERVICE_UUID_MORE_AVAILABLE = 0x04;
	/** < Partial list of 32 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_32BIT_SERVICE_UUID_COMPLETE = 0x05;
	/** < Complete list of 32 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_MORE_AVAILABLE = 0x06;
	/** < Partial list of 128 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_COMPLETE = 0x07;
	/** < Complete list of 128 bit service UUIDs. */
	public static final short BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME = 0x08;
	/** < Short local device name. */
	public static final short BLE_GAP_AD_TYPE_COMPLETE_LOCAL_NAME = 0x09;
	/** < Complete local device name. */
	public static final short BLE_GAP_AD_TYPE_TX_POWER_LEVEL = 0x0A;
	/** < Transmit power level. */
	public static final short BLE_GAP_AD_TYPE_CLASS_OF_DEVICE = 0x0D;
	/** < Class of device. */
	public static final short BLE_GAP_AD_TYPE_SIMPLE_PAIRING_HASH_C = 0x0E;
	/** < Simple Pairing Hash C. */
	public static final short BLE_GAP_AD_TYPE_SIMPLE_PAIRING_RANDOMIZER_R = 0x0F;
	/** < Simple Pairing Randomizer R. */
	public static final short BLE_GAP_AD_TYPE_SECURITY_MANAGER_TK_VALUE = 0x10;
	/** < Security Manager TK Value. */
	public static final short BLE_GAP_AD_TYPE_SECURITY_MANAGER_OOB_FLAGS = 0x11;
	/** < Security Manager Out Of Band Flags. */
	public static final short BLE_GAP_AD_TYPE_SLAVE_CONNECTION_INTERVAL_RANGE = 0x12;
	/** < Slave Connection Interval Range. */
	public static final short BLE_GAP_AD_TYPE_SOLICITED_SERVICE_UUIDS_16BIT = 0x14;
	/** < List of 16-bit Service Solicitation UUIDs. */
	public static final short BLE_GAP_AD_TYPE_SOLICITED_SERVICE_UUIDS_128BIT = 0x15;
	/** < List of 128-bit Service Solicitation UUIDs. */
	public static final short BLE_GAP_AD_TYPE_SERVICE_DATA = 0x16;
	/** < Service Data. */
	public static final short BLE_GAP_AD_TYPE_PUBLIC_TARGET_ADDRESS = 0x17;
	/** < Public Target Address. */
	public static final short BLE_GAP_AD_TYPE_RANDOM_TARGET_ADDRESS = 0x18;
	/** < Random Target Address. */
	public static final short BLE_GAP_AD_TYPE_APPEARANCE = 0x19;
	/** < Appearance. */
	public static final short BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA = 0xFF;

	/** < Manufacturer Specific Data. */


	public ParseLeAdvData() {
		Log.d(TAG, "ParseLeAdvData init....");
	}

	/////// �����㲥����/////////////////////////
	public static byte[] adv_report_parse(short type, byte[] adv_data) {
		int index = 0;
		int length;

		byte[] data;

		byte field_type = 0;
		byte field_length = 0;

		length = adv_data.length;
		while (index < length) {
			try {
				field_length = adv_data[index];
				field_type = adv_data[index + 1];
			} catch (Exception e) {
				Log.d(TAG, "There is a exception here.");
				return null;
			}

			if (field_type == (byte) type) {
				data = new byte[field_length - 1];

				byte i;
				for (i = 0; i < field_length - 1; i++) {
					data[i] = adv_data[index + 2 + i];
				}
				return data;
			}
			index += field_length + 1;
			if (index >= 60) {
				return null;
			}
		}
		return null;
	}

	public static List<String> parse_iBeacon_info(byte[] adv_data)
	{
		byte[] type_data =ParseLeAdvData.adv_report_parse(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA,adv_data);

		if(type_data!=null)
		{
			if(type_data.length==25)
			{
				if((type_data[0] == 0x4C) && (type_data[1] == 0x00))
				{
					byte[] uuid = new byte[16];
					for(int i = 0;i < 16;i++)
					{
						uuid[i] = type_data[4+i];
					}
					int major = (type_data[20]<<8)| type_data[21]; //major
					int minor = (type_data[22]<<8)| type_data[23]; //minor
					int rssi_at_1m =  (int)type_data[24]; //rssi_at_1m

					return Arrays.asList(ByteArrToHex(uuid), Integer.toString(major), Integer.toString(minor), Integer.toString(rssi_at_1m));
				}
				return null;

			}
			return null;

		}
		return null;
	}


	private static String Byte2Hex(Byte paramByte) {
		Object[] arrayOfObject = new Object[1];
		arrayOfObject[0] = paramByte;
		return String.format("%02x", arrayOfObject).toUpperCase();
	}

	private static String ByteArrToHex(byte[] paramArrayOfByte) {
		StringBuilder localStringBuilder = new StringBuilder();
		int i = paramArrayOfByte.length;
		for (int j = 0; j < i; j++) {
			localStringBuilder.append(Byte2Hex(Byte.valueOf(paramArrayOfByte[j])));
//			localStringBuilder.append(" ");
		}
		return localStringBuilder.toString();
	}

	public static byte[] HexToByteArr(String paramString) {
		int j = paramString.length();
		byte[] arrayOfByte;
		if (isOdd(j) != 1) {
			arrayOfByte = new byte[j / 2];
		} else {
			j++;
			arrayOfByte = new byte[j / 2];
			paramString = "0" + paramString;
		}
		int k = 0;
		for (int i = 0; i < j; i += 2) {
			arrayOfByte[k] = HexToByte(paramString.substring(i, i + 2));
			k++;
		}
		return arrayOfByte;
	}

	public static byte HexToByte(String paramString) {
		paramString.replace(" ", "");
		return (byte) Integer.parseInt(paramString, 16);
	}

	public static int isOdd(int paramInt) {
		return paramInt & 0x1;
	}
}
	