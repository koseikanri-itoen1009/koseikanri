create or replace
TRIGGER GMI_ILM_IR_TG
BEFORE INSERT
ON ic_lots_mst
FOR EACH ROW
DECLARE
  -- ===============================
  -- 固定ローカル定数
  -- ===============================
  cv_tg_name   CONSTANT VARCHAR2(100) := 'gmi_ilm_ir_tg'; --トリガ名
  -- ===============================
  -- ユーザー宣言部
  -- ===============================
  -- *** ローカル変数 ***
  ln_count NUMBER;
  lt_item_class_code xxcmn_item_categories_v.segment1%TYPE;
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  unique_constraint_expt      EXCEPTION;     -- 受入情報取得エラー
--
BEGIN
--
  BEGIN
    -- 品目区分を取得
    SELECT xicv.segment1
    INTO lt_item_class_code
    FROM xxcmn_item_categories_v xicv
    WHERE xicv.item_id = :NEW.ITEM_ID
      AND xicv.category_set_name = '品目区分'
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lt_item_class_code := NULL;
  END;
--
-- 品目区分が製品の場合
  IF (lt_item_class_code = '5') THEN
    SELECT COUNT(1)
    INTO ln_count
    FROM ic_lots_mst
    WHERE item_id    = :NEW.item_id
      AND attribute1 = :NEW.attribute1
      AND attribute2 = :NEW.attribute2
-- 2016-06-09 S.Yamashita Add Start
      AND attribute3 = :NEW.attribute3
-- 2016-06-09 S.Yamashita Add End
    ;
--
    IF ( ln_count > 0 ) THEN
      RAISE unique_constraint_expt;
    END IF;
  END IF;
--
EXCEPTION
  WHEN unique_constraint_expt THEN
    /* FND_LOG_MESSAGESテーブルへメッセージ出力 */
    FND_LOG.STRING( 6
                  , cv_tg_name
-- 2016-06-09 S.Yamashita Mod Start
--                  , '主キーが重複するロットが作成される恐れがありました。 品目ID：' || :NEW.ITEM_ID || ' 製造年月日：' || :NEW.ATTRIBUTE1 || ' 固有記号：' || :NEW.ATTRIBUTE2);
                  , '主キーが重複するロットが作成される恐れがありました。 品目ID：' || :NEW.ITEM_ID || ' 製造年月日：' || :NEW.ATTRIBUTE1 || ' 固有記号：' || :NEW.ATTRIBUTE2 || ' 賞味期限：' || :NEW.ATTRIBUTE3);
-- 2016-06-09 S.Yamashita Add Start
    /* 共通例外処理 */
    APP_EXCEPTION.RAISE_EXCEPTION( 'ORA'
                                 , '-20000'
                                 , cv_tg_name || ' 主キーが重複するロットが作成される恐れがありました。');
--
  WHEN OTHERS THEN
    /* 共通例外処理 */
    FND_LOG.STRING( 6
                  , cv_tg_name
                  , sqlerrm);
    APP_EXCEPTION.RAISE_EXCEPTION;
--
END;
/
