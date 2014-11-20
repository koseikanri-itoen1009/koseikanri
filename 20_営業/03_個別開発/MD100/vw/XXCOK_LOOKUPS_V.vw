/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_LOOKUPS_V
 * Description : クイックコードビュー
 * Version     : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *  2009/02/05    1.1   K.Suenaga        [障害COK_008]抽出条件より有効日、無効日の判定を削除
 *  2010/10/08    1.2   S.Arizumi        [E_本稼動_01952]結合条件不足の改善
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_lookups_v
  ( lookup_type                   -- タイプ
   ,meaning_type                  -- タイプ内容
   ,description_type              -- 摘要
   ,lookup_code                   -- コード
   ,meaning                       -- コード内容
   ,description                   -- コード摘要
   ,tag                           -- タグ
   ,start_date_active             -- 開始日
   ,end_date_active               -- 終了日
   ,enabled_flag                  -- 有効フラグ
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
  SELECT fltt.lookup_type         -- タイプ
        ,fltt.meaning             -- タイプ内容
        ,fltt.description         -- 摘要
        ,flv.lookup_code          -- コード
        ,flv.meaning              -- コード内容
        ,flv.description          -- コード摘要
        ,flv.tag                  -- タグ
        ,flv.start_date_active    -- 開始日
        ,flv.end_date_active      -- 終了日
        ,flv.enabled_flag         -- 有効フラグ
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
  FROM   fnd_lookup_types_tl       fltt         -- クイックコードタイプ
        ,fnd_lookup_values         flv          -- クイックコード
  WHERE  fltt.lookup_type        = flv.lookup_type
-- 2010/10/08 Ver.1.2 [E_本稼動_01952] SCS S.Arizumi ADD START
  AND    fltt.view_application_id =  flv.view_application_id
  AND    fltt.security_group_id   =  flv.security_group_id
-- 2010/10/08 Ver.1.2 [E_本稼動_01952] SCS S.Arizumi ADD END
  AND    fltt.language           = flv.language
  AND    fltt.language           = USERENV( 'LANG' )
  AND    flv.enabled_flag        = 'Y'
/
COMMENT ON TABLE  apps.xxcok_lookups_v                   IS 'クイックコードビュー'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.lookup_type       IS 'タイプ'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.meaning_type      IS 'タイプ内容'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.description_type  IS '摘要'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.lookup_code       IS 'コード'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.meaning           IS 'コード内容'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.description       IS 'コード適用'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.tag               IS 'タグ'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.start_date_active IS '開始日'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.end_date_active   IS '終了日'
/
COMMENT ON COLUMN apps.xxcok_lookups_v.enabled_flag      IS '有効フラグ'
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
