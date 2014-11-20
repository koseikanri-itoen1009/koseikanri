create or replace
TRIGGER GMI_ILM_IR_TG
BEFORE INSERT
ON ic_lots_mst
FOR EACH ROW
DECLARE
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
  cv_tg_name   CONSTANT VARCHAR2(100) := 'gmi_ilm_ir_tg'; --�g���K��
  -- ===============================
  -- ���[�U�[�錾��
  -- ===============================
  -- *** ���[�J���ϐ� ***
  ln_count NUMBER;
  lt_item_class_code xxcmn_item_categories_v.segment1%TYPE;
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  unique_constraint_expt      EXCEPTION;     -- ������擾�G���[
--
BEGIN
--
  BEGIN
    -- �i�ڋ敪���擾
    SELECT xicv.segment1
    INTO lt_item_class_code
    FROM xxcmn_item_categories_v xicv
    WHERE xicv.item_id = :NEW.ITEM_ID
      AND xicv.category_set_name = '�i�ڋ敪'
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lt_item_class_code := NULL;
  END;
--
-- �i�ڋ敪�����i�̏ꍇ
  IF (lt_item_class_code = '5') THEN
    SELECT COUNT(1)
    INTO ln_count
    FROM ic_lots_mst
    WHERE item_id    = :NEW.item_id
      AND attribute1 = :NEW.attribute1
      AND attribute2 = :NEW.attribute2
    ;
--
    IF ( ln_count > 0 ) THEN
      RAISE unique_constraint_expt;
    END IF;
  END IF;
--
EXCEPTION
  WHEN unique_constraint_expt THEN
    /* FND_LOG_MESSAGES�e�[�u���փ��b�Z�[�W�o�� */
    FND_LOG.STRING( 6
                  , cv_tg_name
                  , '��L�[���d�����郍�b�g���쐬����鋰�ꂪ����܂����B �i��ID�F' || :NEW.ITEM_ID || ' �����N�����F' || :NEW.ATTRIBUTE1 || ' �ŗL�L���F' || :NEW.ATTRIBUTE2);
    /* ���ʗ�O���� */
    APP_EXCEPTION.RAISE_EXCEPTION( 'ORA'
                                 , '-20000'
                                 , cv_tg_name || ' ��L�[���d�����郍�b�g���쐬����鋰�ꂪ����܂����B');
--
  WHEN OTHERS THEN
    /* ���ʗ�O���� */
    FND_LOG.STRING( 6
                  , cv_tg_name
                  , sqlerrm);
    APP_EXCEPTION.RAISE_EXCEPTION;
--
END;
