CREATE OR REPLACE FORCE VIEW XXCFO_SECURITY_KOUBAI_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_SECURITY_KOUBAI_V
 * Description     : �w���֘A�r���[
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
  lookup_code                           -- ���b�N�A�b�v�R�[�h
) AS
  SELECT flv.lookup_code lookup_code    -- ���b�N�A�b�v�R�[�h
    FROM fnd_lookup_values flv          -- �N�C�b�N�R�[�h
   WHERE flv.lookup_type = 'XXCFO1_SECURITY_KOUBAI'                                 -- �N�C�b�N�R�[�h.���b�N�A�b�v�^�C�v = 'XXCFO1_SECURITY_KOUBAI'�i�Z�L�����e�B�w���֘A����j
     AND flv.language = USERENV( 'LANG' )                                           -- �N�C�b�N�R�[�h.���� = USERENV( 'LANG' )
     AND flv.enabled_flag = 'Y'                                                     -- �N�C�b�N�R�[�h.�L���t���O = 'Y'
     AND TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flv.start_date_active ,SYSDATE ) )    -- TRUNC( �V�X�e�����t ) BETWEEN TRUNC( NVL( �N�C�b�N�R�[�h.�J�n�� ,�V�X�e�����t ) )
                              AND TRUNC( NVL( flv.end_date_active ,SYSDATE ) )      -- AND TRUNC( NVL( �N�C�b�N�R�[�h.�I���� ,�V�X�e�����t ) )
/
