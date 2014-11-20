CREATE OR REPLACE FORCE VIEW XXCFO_PAY_GROUP_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_PAY_GROUP_V
 * Description     : �x���O���[�v�r���[
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/12/18    1.0  SCS ���c     ����쐬
 ************************************************************************/
  lookup_code,                          -- ���b�N�A�b�v�R�[�h
  attribute2                            -- �x���\����
) AS
  SELECT flv.lookup_code lookup_code    -- ���b�N�A�b�v�R�[�h
        ,flv.attribute2 attribute2      -- �x���\����
    FROM fnd_lookup_values flv          -- �N�C�b�N�R�[�h
        ,fnd_application fa             -- �A�v���P�[�V�����Ǘ��}�X�^
   WHERE fa.application_short_name = 'PO'                                           -- �A�v���P�[�V�����Ǘ��}�X�^.�A�v���P�[�V�����Z�k�� = �ePO�f
     AND fa.application_id = flv.view_application_id                                -- �A�v���P�[�V�����Ǘ��}�X�^.�A�v���P�[�V����ID = �x���O���[�v.�r���[�A�v���P�[�V����ID
     AND flv.lookup_type = 'PAY GROUP'                                              -- �x���O���[�v.���b�N�A�b�v�^�C�v = 'PAY GROUP'�i�x���O���[�v�j
     AND flv.language = USERENV( 'LANG' )                                           -- �x���O���[�v.���� = USERENV( 'LANG' )
     AND flv.enabled_flag = 'Y'                                                     -- �x���O���[�v.�L���t���O = 'Y'
     AND TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flv.start_date_active ,SYSDATE ) )    -- TRUNC( �V�X�e�����t ) BETWEEN TRUNC( NVL( �x���O���[�v.�J�n�� ,�V�X�e�����t ) )
                              AND TRUNC( NVL( flv.end_date_active ,SYSDATE ) )      -- AND TRUNC( NVL( �x���O���[�v.�I���� ,�V�X�e�����t ) )
/
