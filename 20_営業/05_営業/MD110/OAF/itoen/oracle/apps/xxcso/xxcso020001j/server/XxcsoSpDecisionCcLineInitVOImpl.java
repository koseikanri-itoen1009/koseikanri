/*============================================================================
* �t�@�C���� : XxcsoSpDecisionCcLineInitVOImpl
* �T�v����   : �ꗥ�����E�e��ʏ����������p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �ꗥ�����E�e��ʏ��������������邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionCcLineInitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionCcLineInitVOImpl()
  {
  }


  public void initQuery(
    String allContainerType
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, allContainerType);

    executeQuery();
  }
}