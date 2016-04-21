/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Script Name      : DBMS_AUDIT_MGMT_SET_AUDIT_TRAIL_LOCATION
 * Description      : �č��\(SYS.AUD$�ASYS.FGA_LOG$)��SYSAUX�\�̈�ֈړ�
 *                    DBMS_AUDIT_MGMT ���g�p�����č��ؐՂ̃����e�i���X(KROWN:140400) (�h�L�������gID 1748595.1)
 * Version          : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/02/09    1.0   T.Kitagawa       [E_�{�ғ�_13496]�V�K�쐬
 *
 *****************************************************************************************/
--
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
    audit_trail_location_value => 'SYSAUX'
  );
END;
/
