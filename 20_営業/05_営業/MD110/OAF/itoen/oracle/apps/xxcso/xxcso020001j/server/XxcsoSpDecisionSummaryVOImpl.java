/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSummaryVOImpl
* �T�v����   : SP�ꌈ���������ʗp�r���[�N���X
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
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP�ꌈ��������ʂ̌������ʂ��擾���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param searchClass      �����敪
   * @param applyBaseCode    �\�����_�R�[�h
   * @param applyUserCode    �\���҃R�[�h
   * @param applyDateStart   �\�����i�J�n�j
   * @param applyDateEnd     �\�����i�I���j
   * @param status           �X�e�[�^�X
   * @param spDecisionNumber SP�ꌈ�ԍ�
   * @param custAccountId    �A�J�E���gID
   *****************************************************************************
   */
  public void initQuery(
    String searchClass
   ,String applyBaseCode
   ,String applyUserCode
   ,Date   applyDateStart
   ,Date   applyDateEnd
   ,String status
   ,String spDecisionNumber
   ,Number custAccountId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, applyBaseCode);
    setWhereClauseParam(index++, applyUserCode);
    setWhereClauseParam(index++, applyDateStart);
    setWhereClauseParam(index++, applyDateEnd);
    setWhereClauseParam(index++, status);
    setWhereClauseParam(index++, spDecisionNumber);
    setWhereClauseParam(index++, custAccountId);

    executeQuery();
  }
}