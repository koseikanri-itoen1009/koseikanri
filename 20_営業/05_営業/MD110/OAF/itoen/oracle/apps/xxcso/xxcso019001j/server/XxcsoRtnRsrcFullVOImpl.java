/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcFullVOImpl
* �T�v����   : �K��E����v���ʁ@���[�gNo�o�^���[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �K��E����v���ʁ@���[�gNo�o�^���[�W�����r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param accountNumber   �ڋq�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, accountNumber);

    executeQuery();
  }
}