/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_LOOKUPS_V
 * Description : �N�C�b�N�R�[�h�r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *  2009/02/05    1.1   K.Suenaga        [��QCOK_008]���o�������L�����A�������̔�����폜
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_lookups_v
  ( lookup_type                   -- �^�C�v
   ,meaning_type                  -- �^�C�v���e
   ,description_type              -- �E�v
   ,lookup_code                   -- �R�[�h
   ,meaning                       -- �R�[�h���e
   ,description                   -- �R�[�h�E�v
   ,tag                           -- �^�O
   ,start_date_active             -- �J�n��
   ,end_date_active               -- �I����
   ,enabled_flag                  -- �L���t���O
   ,attribute1                    -- DFF1
   ,attribute2                    -- DFF2
   ,attribute3                    -- DFF3
   ,attribute4                    -- DFF4
   ,attribute5                    -- DFF5
   ,attribute6                    -- DFF6
   ,attribute7                    -- DFF7
   ,attribute8                    -- DFF8
   ,attribute9                    -- DFF9
   ,attribute10                   -- DFF10
   ,attribute11                   -- DFF11
   ,attribute12                   -- DFF12
   ,attribute13                   -- DFF13
   ,attribute14                   -- DFF14
   ,attribute15                   -- DFF15
  )
AS
  SELECT fltt.lookup_type         -- �^�C�v
        ,fltt.meaning             -- �^�C�v���e
        ,fltt.description         -- �E�v
        ,flv.lookup_code          -- �R�[�h
        ,flv.meaning              -- �R�[�h���e
        ,flv.description          -- �R�[�h�E�v
        ,flv.tag                  -- �^�O
        ,flv.start_date_active    -- �J�n��
        ,flv.end_date_active      -- �I����
        ,flv.enabled_flag         -- �L���t���O
        ,flv.attribute1           -- DFF1
        ,flv.attribute2           -- DFF2
        ,flv.attribute3           -- DFF3
        ,flv.attribute4           -- DFF4
        ,flv.attribute5           -- DFF5
        ,flv.attribute6           -- DFF6
        ,flv.attribute7           -- DFF7
        ,flv.attribute8           -- DFF8
        ,flv.attribute9           -- DFF9
        ,flv.attribute10          -- DFF10
        ,flv.attribute11          -- DFF11
        ,flv.attribute12          -- DFF12
        ,flv.attribute13          -- DFF13
        ,flv.attribute14          -- DFF14
        ,flv.attribute15          -- DFF15
  FROM   fnd_lookup_types_tl       fltt         -- �N�C�b�N�R�[�h�^�C�v
        ,fnd_lookup_values         flv          -- �N�C�b�N�R�[�h
  WHERE  fltt.lookup_type        = flv.lookup_type
  AND    fltt.language           = flv.language
  AND    fltt.language           = USERENV( 'LANG' )
  AND    flv.enabled_flag        = 'Y'
/
COMMENT ON TABLE  apps.xxcok_lookups_v                   IS '�N�C�b�N�R�[�h�r���['
/
COMMENT ON COLUMN apps.xxcok_lookups_v.lookup_type       IS '�^�C�v'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.meaning_type      IS '�^�C�v���e'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.description_type  IS '�E�v'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.lookup_code       IS '�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.meaning           IS '�R�[�h���e'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.description       IS '�R�[�h�K�p'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.tag               IS '�^�O'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.start_date_active IS '�J�n��'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.end_date_active   IS '�I����'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.enabled_flag      IS '�L���t���O'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute1        IS 'DFF1'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute2        IS 'DFF2'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute3        IS 'DFF3'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute4        IS 'DFF4'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute5        IS 'DFF5'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute6        IS 'DFF6'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute7        IS 'DFF7'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute8        IS 'DFF8'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute9        IS 'DFF9'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute10       IS 'DFF10'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute11       IS 'DFF11'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute12       IS 'DFF12'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute13       IS 'DFF13'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute14       IS 'DFF14'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.attribute15       IS 'DFF15'
/
