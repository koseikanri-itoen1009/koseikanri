/*============================================================================
* �t�@�C���� : XxcsoEmpNameSummaryVOImpl
* �T�v����   : �T�������󋵏Ɖ�^�����p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �X�P�W���[�����[�W�����i�S���Җ��j���������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpNameSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpNameSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param empName    �S���Җ�
   *****************************************************************************
   */
  public void initQuery(
    String empName
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, empName);

    // SQL���s
    executeQuery();
  }

}