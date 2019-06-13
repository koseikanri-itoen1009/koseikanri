/************************************************************************************
 * Copyright(c) 2018, SCSK Corporation. All rights reserved..
 *
 * View Name       : xxcos_reduced_tax_rate_v
 * Description     : �i�ڕʏ���ŗ�view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2019/06/04    1.0   S.Kuwako         �V�K�쐬
 *
 ************************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcos_reduced_tax_rate_v(
   item_code                            -- �i�ڃR�[�h
 , class_for_variable_tax               -- �y���ŗ��p�Ŏ��
 , tax_name                             -- �ŗ��L�[����
 , tax_description                      -- �E�v
 , tax_histories_code                   -- ����ŗ����R�[�h
 , tax_histories_description            -- ����ŗ��𖼏�
 , start_date                           -- �ŗ��L�[_�J�n��
 , end_date                             -- �ŗ��L�[_�I����
 , start_date_histories                 -- ����ŗ���_�J�n��
 , end_date_histories                   -- ����ŗ���_�I����
 , tax_rate                             -- ����ŗ�
 , tax_class_suppliers_outside          -- �ŋ敪_�d���O��
 , tax_class_suppliers_inside           -- �ŋ敪_�d������
 , tax_class_sales_outside              -- �ŋ敪_����O��
 , tax_class_sales_inside               -- �ŋ敪_�������
)
AS
  SELECT  xsib.item_code             item_code                    -- �i�ڃR�[�h
         ,flv1.lookup_code           class_for_variable_tax       -- �y���ŗ��p�Ŏ��
         ,flv1.meaning               tax_name                     -- �ŗ��L�[����
         ,flv1.description           tax_description              -- �E�v
         ,flv2.meaning               tax_histories_code           -- ����ŗ����R�[�h
         ,flv2.description           tax_histories_description    -- ����ŗ��𖼏�
         ,flv1.start_date_active     start_date                   -- �ŗ��L�[_�J�n��
         ,flv1.end_date_active       end_date                     -- �ŗ��L�[_�I����
         ,flv2.start_date_active     start_date_histories         -- ����ŗ���_�J�n��
         ,flv2.end_date_active       end_date_histories           -- ����ŗ���_�I����
         ,TO_NUMBER(flv2.attribute1) tax_rate                     -- ����ŗ�
         ,flv2.attribute2            tax_class_suppliers_outside  -- �ŋ敪_�d���O��
         ,flv2.attribute3            tax_class_suppliers_inside   -- �ŋ敪_�d������
         ,flv2.attribute4            tax_class_sales_outside      -- �ŋ敪_����O��
         ,flv2.attribute5            tax_class_sales_inside       -- �ŋ敪_�������
  FROM    fnd_lookup_values          flv1                         -- �y���ŗ��p�Ŏ�ʃ}�X�^
         ,fnd_lookup_values          flv2                         -- �y���ŗ������}�X�^
         ,xxcmm_system_items_b       xsib                         -- DISC�i�ڃA�h�I��
  WHERE   flv1.lookup_code             =  flv2.tag
  AND     xsib.class_for_variable_tax  =  flv1.lookup_code
  AND     flv1.lookup_type             = 'XXCFO1_TAX_CODE'
  AND     flv2.lookup_type             = 'XXCFO1_TAX_CODE_HISTORIES'
  AND     flv1.language                =  USERENV( 'LANG' )
  AND     flv2.language                =  USERENV( 'LANG' )
  AND     flv1.enabled_flag            = 'Y'
  AND     flv2.enabled_flag            = 'Y'
  ;
--
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.item_code                   IS  '�i�ڃR�[�h';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.class_for_variable_tax      IS  '�y���ŗ��p�Ŏ��';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_name                    IS  '�ŗ��L�[����';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_description             IS  '�E�v';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_code          IS  '����ŗ����R�[�h';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_description   IS  '����ŗ��𖼏�';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date                  IS  '�ŗ��L�[_�J�n��';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date                    IS  '�ŗ��L�[_�I����';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date_histories        IS  '����ŗ���_�J�n��';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date_histories          IS  '����ŗ���_�I����';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_rate                    IS  '����ŗ�';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_outside IS  '�ŋ敪_�d���O��';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_inside  IS  '�ŋ敪_�d������';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_outside     IS  '�ŋ敪_����O��';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_inside      IS  '�ŋ敪_�������';
--
COMMENT ON  TABLE   xxcos_reduced_tax_rate_v                             IS  'XXCOS�i�ڕʏ���ŗ��r���[';
