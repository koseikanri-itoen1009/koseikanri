/*============================================================================
* �t�@�C���� : XxcsoContractCreateInitVOImpl
* �T�v����   : �V�K�쐬���_��Ǘ��������擾�r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2009-02-16 1.1  SCS�������l  [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
* 2009-02-17 1.1  SCS�������l  [CT1-012]�ݒu�於�擾�����C��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �V�K�쐬���_��Ǘ��������擾�r���[�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractCreateInitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractCreateInitVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_�[ID
   *****************************************************************************
   */
  public void initQuery(
    String spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}