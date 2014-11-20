/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchInitVOImpl
* �T�v����   : SP�ꌈ��������ʏ����l�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0   SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * SP�ꌈ��������ʂ̏����l��ݒ肷�邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchInitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchInitVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param searchClass �����敪
   *****************************************************************************
   */
  public void initQuery(
    String searchClass
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);

    executeQuery();
  }
}