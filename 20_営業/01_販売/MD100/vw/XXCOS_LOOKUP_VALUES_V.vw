/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_lookup_values_v
 * Description     : �N�C�b�N�R�[�hview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   S.Tomita         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_lookup_values_v (
  lookup_type
 ,lookup_code
 ,meaning
 ,description
 ,start_date_active
 ,end_date_active
 ,security_group_id
 ,view_application_id
 ,attribute_category
 ,attribute1
 ,attribute2
 ,attribute3
 ,attribute4
 ,attribute5
 ,attribute6
 ,attribute7
 ,attribute8
 ,attribute9
 ,attribute10
 ,attribute11
 ,attribute12
 ,attribute13
 ,attribute14
 ,attribute15
 ,tag
)
AS
  SELECT flv.lookup_type
        ,flv.lookup_code
        ,flv.meaning
        ,flv.description
        ,flv.start_date_active
        ,flv.end_date_active
        ,flv.security_group_id
        ,flv.view_application_id
        ,flv.attribute_category
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
        ,flv.attribute11
        ,flv.attribute12
        ,flv.attribute13
        ,flv.attribute14
        ,flv.attribute15
        ,flv.tag
  FROM   fnd_lookup_values flv
  WHERE  flv.enabled_flag = 'Y'
  AND    flv.language = userenv('LANG')
  AND    flv.source_lang = userenv('LANG')
;
COMMENT ON  COLUMN  xxcos_lookup_values_v.lookup_type          IS  '�Q�ƃ^�C�v';
COMMENT ON  COLUMN  xxcos_lookup_values_v.lookup_code          IS  '�Q�ƃR�[�h';
COMMENT ON  COLUMN  xxcos_lookup_values_v.meaning              IS  '���e';
COMMENT ON  COLUMN  xxcos_lookup_values_v.description          IS  '�E�v';
COMMENT ON  COLUMN  xxcos_lookup_values_v.start_date_active    IS  '�L���J�n��';
COMMENT ON  COLUMN  xxcos_lookup_values_v.end_date_active      IS  '�L���I����';
COMMENT ON  COLUMN  xxcos_lookup_values_v.security_group_id    IS  '�Z�L�����e�B�O���[�vID';
COMMENT ON  COLUMN  xxcos_lookup_values_v.view_application_id  IS  '�r���[�A�v���P�[�V����ID';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute_category   IS  '�R���e�L�X�g';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute1           IS  '����1';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute2           IS  '����2';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute3           IS  '����3';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute4           IS  '����4';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute5           IS  '����5';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute6           IS  '����6';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute7           IS  '����7';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute8           IS  '����8';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute9           IS  '����9';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute10          IS  '����10';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute11          IS  '����11';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute12          IS  '����12';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute13          IS  '����13';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute14          IS  '����14';
COMMENT ON  COLUMN  xxcos_lookup_values_v.attribute15          IS  '����15';
COMMENT ON  COLUMN  xxcos_lookup_values_v.tag                  IS  '�^�O';
--
COMMENT ON  TABLE   xxcos_lookup_values_v                      IS  '�N�C�b�N�R�[�h�r���[';
