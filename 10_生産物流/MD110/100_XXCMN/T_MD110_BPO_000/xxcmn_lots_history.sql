CREATE OR REPLACE
PROCEDURE xxcmn_lots_history(
            in_item_id                       IN ic_lots_mst.item_id%TYPE
          , in_lot_id                        IN ic_lots_mst.lot_id%TYPE
          , iv_lot_desc                      IN ic_lots_mst.lot_desc%TYPE
          , iv_qc_grade                      IN ic_lots_mst.qc_grade%TYPE
          , iv_expaction_code                IN ic_lots_mst.expaction_code%TYPE
          , id_expaction_date                IN ic_lots_mst.expaction_date%TYPE
          , id_lot_created                   IN ic_lots_mst.lot_created%TYPE
          , id_expire_date                   IN ic_lots_mst.expire_date%TYPE
          , id_retest_date                   IN ic_lots_mst.retest_date%TYPE
          , iv_strength                      IN ic_lots_mst.strength%TYPE
          , in_inactive_ind                  IN ic_lots_mst.inactive_ind%TYPE
          , in_shipvend_id                   IN ic_lots_mst.shipvend_id%TYPE
          , iv_vendor_lot_no                 IN ic_lots_mst.vendor_lot_no%TYPE
          , in_last_updated_by               IN ic_lots_mst.last_updated_by%TYPE
          , in_last_update_login             IN ic_lots_mst.last_update_login%TYPE
          , iv_attribute1                    IN ic_lots_mst.attribute1%TYPE
          , iv_attribute2                    IN ic_lots_mst.attribute2%TYPE
          , iv_attribute3                    IN ic_lots_mst.attribute3%TYPE
          , iv_attribute4                    IN ic_lots_mst.attribute4%TYPE
          , iv_attribute5                    IN ic_lots_mst.attribute5%TYPE
          , iv_attribute6                    IN ic_lots_mst.attribute6%TYPE
          , iv_attribute8                    IN ic_lots_mst.attribute8%TYPE
          , iv_attribute9                    IN ic_lots_mst.attribute9%TYPE
          , iv_attribute10                   IN ic_lots_mst.attribute10%TYPE
          , iv_attribute11                   IN ic_lots_mst.attribute11%TYPE
          , iv_attribute12                   IN ic_lots_mst.attribute12%TYPE
          , iv_attribute13                   IN ic_lots_mst.attribute13%TYPE
          , iv_attribute14                   IN ic_lots_mst.attribute14%TYPE
          , iv_attribute15                   IN ic_lots_mst.attribute15%TYPE
          , iv_attribute16                   IN ic_lots_mst.attribute16%TYPE
          , iv_attribute17                   IN ic_lots_mst.attribute17%TYPE
          , iv_attribute18                   IN ic_lots_mst.attribute18%TYPE
          , iv_attribute19                   IN ic_lots_mst.attribute19%TYPE
          , iv_attribute20                   IN ic_lots_mst.attribute20%TYPE
          , iv_attribute21                   IN ic_lots_mst.attribute21%TYPE
          , iv_attribute22                   IN ic_lots_mst.attribute22%TYPE
          , iv_attribute23                   IN ic_lots_mst.attribute23%TYPE
          , iv_attribute24                   IN ic_lots_mst.attribute24%TYPE
          , iv_attribute25                   IN ic_lots_mst.attribute25%TYPE
           ) IS
--
    -- *** ローカル・カーソル ***
    CURSOR  lots_mst_cur (
            in_item_id                       IN ic_lots_mst.item_id%TYPE
          , in_lot_id                        IN ic_lots_mst.lot_id%TYPE
    ) IS
      SELECT   ilm.item_id                   AS item_id
             , ilm.lot_id                    AS lot_id
             , ilm.lot_no                    AS lot_no
             , ilm.sublot_no                 AS sublot_no
             , ilm.lot_desc                  AS lot_desc
             , ilm.qc_grade                  AS qc_grade
             , ilm.expaction_code            AS expaction_code
             , ilm.expaction_date            AS expaction_date
             , ilm.lot_created               AS lot_created
             , ilm.expire_date               AS expire_date
             , ilm.retest_date               AS retest_date
             , ilm.strength                  AS strength
             , ilm.inactive_ind              AS inactive_ind
             , ilm.origination_type          AS origination_type
             , ilm.shipvend_id               AS shipvend_id
             , ilm.vendor_lot_no             AS vendor_lot_no
             , ilm.creation_date             AS creation_date
             , ilm.last_update_date          AS last_update_date
             , ilm.created_by                AS created_by
             , ilm.last_updated_by           AS last_updated_by
             , ilm.trans_cnt                 AS trans_cnt
             , ilm.delete_mark               AS delete_mark
             , ilm.text_code                 AS text_code
             , ilm.last_update_login         AS last_update_login
             , ilm.program_application_id    AS program_application_id
             , ilm.program_id                AS program_id
             , ilm.program_update_date       AS program_update_date
             , ilm.request_id                AS request_id
             , ilm.attribute1                AS attribute1
             , ilm.attribute2                AS attribute2
             , ilm.attribute3                AS attribute3
             , ilm.attribute4                AS attribute4
             , ilm.attribute5                AS attribute5
             , ilm.attribute6                AS attribute6
             , ilm.attribute7                AS attribute7
             , ilm.attribute8                AS attribute8
             , ilm.attribute9                AS attribute9
             , ilm.attribute10               AS attribute10
             , ilm.attribute11               AS attribute11
             , ilm.attribute12               AS attribute12
             , ilm.attribute13               AS attribute13
             , ilm.attribute14               AS attribute14
             , ilm.attribute15               AS attribute15
             , ilm.attribute16               AS attribute16
             , ilm.attribute17               AS attribute17
             , ilm.attribute18               AS attribute18
             , ilm.attribute19               AS attribute19
             , ilm.attribute20               AS attribute20
             , ilm.attribute22               AS attribute22
             , ilm.attribute21               AS attribute21
             , ilm.attribute23               AS attribute23
             , ilm.attribute24               AS attribute24
             , ilm.attribute25               AS attribute25
             , ilm.attribute26               AS attribute26
             , ilm.attribute27               AS attribute27
             , ilm.attribute28               AS attribute28
             , ilm.attribute29               AS attribute29
             , ilm.attribute30               AS attribute30
             , ilm.attribute_category        AS attribute_category
             , ilm.odm_lot_number            AS odm_lot_number
      FROM     ic_lots_mst   ilm
      WHERE    ilm.item_id = in_item_id
      AND      ilm.lot_id  = in_lot_id;
--
    -- *** ローカル定数 ***
    cn_zero                                     CONSTANT NUMBER := 0;
    cn_one                                      CONSTANT NUMBER := 1;
--
    --  ローカル変数
    lr_lots_mst_rec                             lots_mst_cur%ROWTYPE;                        -- ロットマスタ情報
    ln_history_no                               xxcmn_lots_mst_history.history_no%TYPE;      -- 履歴番号
--
--  処理部
--
BEGIN
--
    --  ロットIDに設定がある（更新）の場合、下記の処理を行います。
    IF (in_lot_id IS NOT NULL ) THEN
--
      --  ロットマスタ履歴テーブルより発行済最大履歴番号を取得
      BEGIN
        SELECT NVL( MAX( xlmh.history_no ) , cn_zero )      history_no
        INTO   ln_history_no
        FROM   xxcmn_lots_mst_history  xlmh
        WHERE  xlmh.item_id = in_item_id
        AND    xlmh.lot_id  = in_lot_id;
      END;
--
      --  ロット情報取得
      OPEN lots_mst_cur(
           in_item_id
          ,in_lot_id
      );
      FETCH lots_mst_cur INTO lr_lots_mst_rec;
      CLOSE lots_mst_cur;
--
      -- 発行済最大履歴番号確認
      IF ( ln_history_no = cn_zero ) THEN
--
        --  履歴番号加算
        ln_history_no := ln_history_no + cn_one;
--
        -- 変更前ロット情報を履歴テーブルに登録
        INSERT INTO xxcmn_lots_mst_history(
          item_id
        , lot_id
        , history_no
        , lot_no
        , sublot_no
        , lot_desc
        , qc_grade
        , expaction_code
        , expaction_date
        , lot_created
        , expire_date
        , retest_date
        , strength
        , inactive_ind
        , origination_type
        , shipvend_id
        , vendor_lot_no
        , creation_date
        , last_update_date
        , created_by
        , last_updated_by
        , trans_cnt
        , delete_mark
        , text_code
        , last_update_login
        , program_application_id
        , program_id
        , program_update_date
        , request_id
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute7
        , attribute8
        , attribute9
        , attribute10
        , attribute11
        , attribute12
        , attribute13
        , attribute14
        , attribute15
        , attribute16
        , attribute17
        , attribute18
        , attribute19
        , attribute20
        , attribute21
        , attribute22
        , attribute23
        , attribute24
        , attribute25
        , attribute26
        , attribute27
        , attribute28
        , attribute29
        , attribute30
        , attribute_category
        , odm_lot_number
        )
        VALUES(
          lr_lots_mst_rec.item_id
        , lr_lots_mst_rec.lot_id
        , ln_history_no
        , lr_lots_mst_rec.lot_no
        , lr_lots_mst_rec.sublot_no
        , lr_lots_mst_rec.lot_desc
        , lr_lots_mst_rec.qc_grade
        , lr_lots_mst_rec.expaction_code
        , lr_lots_mst_rec.expaction_date
        , lr_lots_mst_rec.lot_created
        , lr_lots_mst_rec.expire_date
        , lr_lots_mst_rec.retest_date
        , lr_lots_mst_rec.strength
        , lr_lots_mst_rec.inactive_ind
        , lr_lots_mst_rec.origination_type
        , lr_lots_mst_rec.shipvend_id
        , lr_lots_mst_rec.vendor_lot_no
        , lr_lots_mst_rec.creation_date
        , lr_lots_mst_rec.last_update_date
        , lr_lots_mst_rec.created_by
        , lr_lots_mst_rec.last_updated_by
        , lr_lots_mst_rec.trans_cnt
        , lr_lots_mst_rec.delete_mark
        , lr_lots_mst_rec.text_code
        , lr_lots_mst_rec.last_update_login
        , lr_lots_mst_rec.program_application_id
        , lr_lots_mst_rec.program_id
        , lr_lots_mst_rec.program_update_date
        , lr_lots_mst_rec.request_id
        , lr_lots_mst_rec.attribute1
        , lr_lots_mst_rec.attribute2
        , lr_lots_mst_rec.attribute3
        , lr_lots_mst_rec.attribute4
        , lr_lots_mst_rec.attribute5
        , lr_lots_mst_rec.attribute6
        , lr_lots_mst_rec.attribute7
        , lr_lots_mst_rec.attribute8
        , lr_lots_mst_rec.attribute9
        , lr_lots_mst_rec.attribute10
        , lr_lots_mst_rec.attribute11
        , lr_lots_mst_rec.attribute12
        , lr_lots_mst_rec.attribute13
        , lr_lots_mst_rec.attribute14
        , lr_lots_mst_rec.attribute15
        , lr_lots_mst_rec.attribute16
        , lr_lots_mst_rec.attribute17
        , lr_lots_mst_rec.attribute18
        , lr_lots_mst_rec.attribute19
        , lr_lots_mst_rec.attribute20
        , lr_lots_mst_rec.attribute21
        , lr_lots_mst_rec.attribute22
        , lr_lots_mst_rec.attribute23
        , lr_lots_mst_rec.attribute24
        , lr_lots_mst_rec.attribute25
        , lr_lots_mst_rec.attribute26
        , lr_lots_mst_rec.attribute27
        , lr_lots_mst_rec.attribute28
        , lr_lots_mst_rec.attribute29
        , lr_lots_mst_rec.attribute30
        , lr_lots_mst_rec.attribute_category
        , lr_lots_mst_rec.odm_lot_number
        );
      END IF;
--
      --  発番済履歴番号に１加算
      ln_history_no := ln_history_no + cn_one;
--
      --  変更後のロット情報を履歴テーブルに登録
      INSERT INTO xxcmn_lots_mst_history(
        item_id
      , lot_id
      , history_no
      , lot_no
      , sublot_no
      , lot_desc
      , qc_grade
      , expaction_code
      , expaction_date
      , lot_created
      , expire_date
      , retest_date
      , strength
      , inactive_ind
      , origination_type
      , shipvend_id
      , vendor_lot_no
      , creation_date
      , last_update_date
      , created_by
      , last_updated_by
      , trans_cnt
      , delete_mark
      , text_code
      , last_update_login
      , program_application_id
      , program_id
      , program_update_date
      , request_id
      , attribute1
      , attribute2
      , attribute3
      , attribute4
      , attribute5
      , attribute6
      , attribute7
      , attribute8
      , attribute9
      , attribute10
      , attribute11
      , attribute12
      , attribute13
      , attribute14
      , attribute15
      , attribute16
      , attribute17
      , attribute18
      , attribute19
      , attribute20
      , attribute21
      , attribute22
      , attribute23
      , attribute24
      , attribute25
      , attribute26
      , attribute27
      , attribute28
      , attribute29
      , attribute30
      , attribute_category
      , odm_lot_number
      )
      VALUES(
        lr_lots_mst_rec.item_id
      , lr_lots_mst_rec.lot_id
      , ln_history_no
      , lr_lots_mst_rec.lot_no
      , lr_lots_mst_rec.sublot_no
      , iv_lot_desc
      , iv_qc_grade
      , iv_expaction_code
      , id_expaction_date
      , id_lot_created
      , id_expire_date
      , id_retest_date
      , iv_strength
      , in_inactive_ind
      , lr_lots_mst_rec.origination_type
      , in_shipvend_id
      , iv_vendor_lot_no
      , lr_lots_mst_rec.creation_date
      , sysdate
      , lr_lots_mst_rec.created_by
      , in_last_updated_by
      , lr_lots_mst_rec.trans_cnt
      , lr_lots_mst_rec.delete_mark
      , lr_lots_mst_rec.text_code
      , in_last_update_login
      , lr_lots_mst_rec.program_application_id
      , lr_lots_mst_rec.program_id
      , lr_lots_mst_rec.program_update_date
      , lr_lots_mst_rec.request_id
      , iv_attribute1
      , iv_attribute2
      , iv_attribute3
      , iv_attribute4
      , iv_attribute5
      , iv_attribute6
      , lr_lots_mst_rec.attribute7
      , iv_attribute8
      , iv_attribute9
      , iv_attribute10
      , iv_attribute11
      , iv_attribute12
      , iv_attribute13
      , iv_attribute14
      , iv_attribute15
      , iv_attribute16
      , iv_attribute17
      , iv_attribute18
      , iv_attribute19
      , iv_attribute20
      , iv_attribute21
      , iv_attribute22
      , iv_attribute23
      , iv_attribute24
      , iv_attribute25
      , lr_lots_mst_rec.attribute26
      , lr_lots_mst_rec.attribute27
      , lr_lots_mst_rec.attribute28
      , lr_lots_mst_rec.attribute29
      , lr_lots_mst_rec.attribute30
      , lr_lots_mst_rec.attribute_category
      , lr_lots_mst_rec.odm_lot_number
      );
--
    END IF;
--
END xxcmn_lots_history;
