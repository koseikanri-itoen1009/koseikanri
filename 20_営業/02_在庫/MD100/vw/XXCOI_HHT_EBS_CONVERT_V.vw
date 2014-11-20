/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name     : XXCOI_HHT_EBS_CONVERT_V
 * Description   : ���o�ɃW���[�i���R�[�h�ϊ��r���[
 * Version       : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date         Ver.  Editor     Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-11-17   1.0   SCS H.Nakajima   �V�K�쐬
 *  2009-01-21   1.1   SCS H.Nakajima   �L�����A�������̒ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_hht_ebs_convert_v(
   lookup_type
  ,lookup_code
  ,lookup_meaning
  ,record_type
  ,invoice_type
  ,department_flag
  ,outside_subinv_code_conv_div
  ,inside_subinv_code_conv_div
  ,program_div
  ,consume_vd_flag
  ,stock_uncheck_list_div
  ,stock_balance_list_div
  ,item_convert_div
  ,start_date_active
  ,end_date_active
) AS SELECT 
   flv.lookup_type 
  ,flv.lookup_code 
  ,flv.meaning   
  ,flv.attribute1  
  ,flv.attribute2  
  ,flv.attribute3  
  ,flv.attribute4  
  ,flv.attribute5  
  ,flv.attribute6  
  ,flv.attribute7  
  ,flv.attribute8  
  ,flv.attribute9  
  ,flv.attribute10 
  ,flv.start_date_active
  ,flv.end_date_active
FROM fnd_lookup_values flv
WHERE flv.lookup_type  = 'XXCOI1_HHT_EBS_CONVERT_TABLE'
AND   flv.language     = USERENV( 'LANG' )
AND   flv.enabled_flag = 'Y'
/
COMMENT ON TABLE xxcoi_hht_ebs_convert_v IS '���o�ɃW���[�i���R�[�h�ϊ��r���['
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_type IS '�N�C�b�N�R�[�h�^�C�v'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_code IS '�N�C�b�N�R�[�h'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_meaning IS '�Ӗ�'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.record_type IS '���R�[�h���'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.invoice_type IS '�`�[�敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.department_flag IS '�S�ݓX�t���O'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div IS '�o�ɑ��ۊǏꏊ�ϊ��敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div IS '���ɑ��ۊǏꏊ�ϊ��敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.program_div IS '���o�ɃW���[�i�������敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.consume_vd_flag IS '����VD�Ώۃt���O'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.stock_uncheck_list_div IS '���ɖ��m�F���X�g�Ώۋ敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.stock_balance_list_div IS '���ɍ��يm�F���X�g�Ώۋ敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.item_convert_div IS '���i�U�֋敪'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.start_date_active IS '�J�n��'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.end_date_active IS '�I����'
/
