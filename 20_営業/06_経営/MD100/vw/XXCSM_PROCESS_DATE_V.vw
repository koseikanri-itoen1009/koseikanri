CREATE OR REPLACE VIEW XXCSM_PROCESS_DATE_V
(
  process_date
)
AS
  SELECT xpcd.process_date    process_date
  FROM   xxccp_process_dates  xpcd
  WHERE  rownum = 1
;
--
COMMENT ON COLUMN xxcsm_process_date_v.process_date         IS '�Ɩ�������';
--
COMMENT ON TABLE  xxcsm_process_date_v IS '�Ɩ��������擾�r���[';
