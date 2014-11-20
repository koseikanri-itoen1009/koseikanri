CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_STC_LOT_NO_V" (
  "LOT_NO"
  ) AS 
  SELECT
    ILM.LOT_NO             -- ���b�gNo
  FROM   IC_LOTS_MST ILM  -- OPM���b�g�}�X�^
  WHERE  ILM.LOT_ID > 0
  GROUP BY
        ILM.LOT_NO
  ORDER BY 
        ILM.LOT_NO
  ;
--
COMMENT ON COLUMN XXINV_STC_LOT_NO_V.LOT_NO   IS '���b�gNo';
--
COMMENT ON TABLE  XXINV_STC_LOT_NO_V IS '�݌�_�l�Z�b�g�pVIEW_���b�gNO' ;
/