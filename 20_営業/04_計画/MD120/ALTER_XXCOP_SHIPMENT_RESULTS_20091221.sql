/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_SHIPMENT_RESULTS
 * Description     : �e�R�[�h�o�׎��ѕ\(ALTER��)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_SHIPMENT_RESULTS
 ADD (
  ARRIVAL_DATE            DATE
 );
--
COMMENT ON COLUMN XXCOP.XXCOP_SHIPMENT_RESULTS.ARRIVAL_DATE         IS '���ד�';
--
