/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_for_sls_prsn_v
 * Description     : ���ʗp�F���[�g�c�ƈ��p������уr���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_for_sls_prsn_v
(
  account_number
 ,order_no_hht
 ,delivery_date
 ,pure_amount
)
AS
SELECT xsv.account_number    -- �ڋq�y�[�i��z
      ,xsv.order_no_hht      -- ��No(HHT)
      ,xsv.delivery_date     -- �[�i��
      ,xsv.pure_amount       -- �{�̋��z�i���ׁj
FROM   xxcso_sales_v xsv
WHERE  xsv.delivery_pattern_class in ('1','2','3','4','6') -- �[�i�`�ԋ敪�i5:�����_�q�ɔ���ȊO�j
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_FOR_SLS_PRSN_V IS '���ʗp�F���[�g�c�ƈ��p������уr���[';
