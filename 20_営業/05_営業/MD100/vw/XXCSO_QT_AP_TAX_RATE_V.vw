/*************************************************************************
 * 
 * VIEW Name       : XXCSO_QT_AP_TAX_RATE_V
 * Description     : ���ϗp�����ŗ��擾�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2011/05/17    1.0  K.Kiriu      ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_QT_AP_TAX_RATE_V
(
  ap_tax_rate
)
AS
  SELECT  1 + ( NVL(atca.tax_rate, 0) / 100 ) ap_tax_rate
  FROM    ap_tax_codes_all atca
  WHERE   atca.name              = fnd_profile.value( 'XXCSO1_QT_AP_TAX_RATE' )                        --�����ŃR�[�h
  AND     atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --��v����ID
  AND     xxcso_util_common_pkg.get_online_sysdate BETWEEN atca.start_date
                          AND     NVL( atca.inactive_date, xxcso_util_common_pkg.get_online_sysdate )  --�K�p�J�n�A�I��
  AND     atca.enabled_flag      = 'Y'                                       --�L���t���O
  AND     atca.attribute2        = '1'                                       --�ېŏW�v�Ώ�(�ېŔ���)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.ap_tax_rate IS '�����ŗ�';
COMMENT ON TABLE XXCSO_QT_AP_TAX_RATE_V IS '���ϗp�����ŗ��擾�r���[';
