/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_ASSIGNMENT_CONTROLS
 * Description     : ���ʉ�������}�X�^�R���g���[���e�[�u��(ALTER��)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_ASSIGNMENT_CONTROLS
 ADD (
  SHIP_FROM_CODE          VARCHAR2(4),
  SHIP_TO_CODE            VARCHAR2(4),
  PROD_START_DATE         DATE
 );
--
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.SHIP_FROM_CODE         IS '�o�׌��q��';
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.SHIP_TO_CODE           IS '���ɐ�q��';
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.PROD_START_DATE        IS '�����N����';
--