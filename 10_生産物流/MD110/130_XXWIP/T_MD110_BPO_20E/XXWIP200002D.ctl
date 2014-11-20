-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : XXWIP200002D(ctl)
-- Description      : HHT出来高実績 SQL*Loader処理
-- Version          : 1.1
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2007/12/25    1.0   Oracle 伊東 愛美  初回作成
--  2008/06/12    1.1   Oracle 二瓶 大輔  ST不具合対応#79対応(日付書式を「YYYY/MM/DD」に変更)
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWIP_VOLUME_ACTUAL_IF
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
VOLUME_ACTUAL_IF_ID          SEQUENCE(MAX,1),
PLANT_CODE                   POSITION(1),
BATCH_NO                     POSITION(*),
ITEM_CODE                    POSITION(*),
VOLUME_ACTUAL_QTY            POSITION(*),
RCV_DATE                     POSITION(*)        DATE(10)"YYYY/MM/DD",
ACTUAL_DATE                  POSITION(*)        DATE(10)"YYYY/MM/DD",
MAKER_DATE                   POSITION(*)        DATE(10)"YYYY/MM/DD",
EXPIRATION_DATE              POSITION(*)        DATE(10)"YYYY/MM/DD"
)
