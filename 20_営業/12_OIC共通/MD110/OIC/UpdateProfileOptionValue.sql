--------------------------------------------------------
--  DDL for Procedure UPDATEPROFILEOPTIONVALUE
--------------------------------------------------------

CREATE OR REPLACE PROCEDURE "UPDATEPROFILEOPTIONVALUE"
(
	profileOptionId		IN NUMBER,
	levelName			IN VARCHAR2,
	levelValue			IN VARCHAR2,
	profileOptionValue	IN VARCHAR2,
	lastUpdatedBy		IN VARCHAR2)
IS
BEGIN
	UPDATE XXCCD_PROFILE_OPTION_VALUES 
	SET PROFILE_OPTION_VALUE = profileOptionValue, 
		LAST_UPDATED_BY		 = lastUpdatedBy, 
		LAST_UPDATE_DATE	 = SYSTIMESTAMP AT TIME ZONE 'UTC' 
	WHERE PROFILE_OPTION_ID	 = profileOptionId 
		AND LEVEL_NAME		 = levelName 
		AND LEVEL_VALUE		 = levelValue;

	IF SQL%ROWCOUNT = 0
		THEN RAISE_APPLICATION_ERROR(-20000, '更新対象のレコードがありません');
	END IF;
END;
/
