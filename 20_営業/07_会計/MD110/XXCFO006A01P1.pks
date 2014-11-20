CREATE OR REPLACE PACKAGE XXCFO006A01P1
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFO006A01P1(spec)
 * Description     : APWI�Z�L�����e�B
 * MD.050          : MD050_CFO_006_A01_APWI�Z�L�����e�B
 * MD.070          : MD050_CFO_006_A01_APWI�Z�L�����e�B
 * Version         : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_policy_condition      F    VAR    WHERE��i�������匠������ɂ��Z�L�����e�B�ݒ�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05   1.0    SCS ���c �E�l    ����쐬
 *
 *****************************************************************************************/
--
  --
  --APWI�Z�L�����e�B
  FUNCTION get_policy_condition(
    p1 IN VARCHAR2            -- 1.DammyParameter for Fine-Grain-Access-Control
   ,p2 IN VARCHAR2)           -- 2.DammyParameter for Fine-Grain-Access-Control
  RETURN VARCHAR2;            -- WHERE��i�������匠������ɂ��Z�L�����e�B�ݒ�j
  --
--
END XXCFO006A01P1;
/
