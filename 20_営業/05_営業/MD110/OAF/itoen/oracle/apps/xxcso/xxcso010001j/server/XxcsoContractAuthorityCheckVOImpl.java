/*============================================================================
* �t�@�C���� : XxcsoContractAuthorityCheckVOImpl
* �T�v����   : �����`�F�b�N�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-20 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * �����`�F�b�N���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractAuthorityCheckVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractAuthorityCheckVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param spDecisionHeaderId     SP�ꌈ�w�b�_ID
   *****************************************************************************
   */
  public void getAuthority(
    Number spDecisionHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionHeaderId);

    executeQuery();
  }
}