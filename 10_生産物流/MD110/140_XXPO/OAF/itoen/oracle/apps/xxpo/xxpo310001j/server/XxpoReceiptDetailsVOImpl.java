/*============================================================================
* �t�@�C���� : XxpoReceiptDetailsVOImpl
* �T�v����   : �����������:������׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-05 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * ������׃r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoReceiptDetailsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoReceiptDetailsVOImpl()
  {
  }
  
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams �����p�����[�^�pHashMap
   ****************************************************************************/
  public void initQuery(
    HashMap searchParams // �����L�[�p�����[�^
   )
  {

    // ������
    setWhereClauseParams(null);

    // �����p�����[�^(�����ԍ�)
    String serchHeaderNumber = (String)searchParams.get("headerNumber");
    // �����p�����[�^(�������הԍ�)
    String serchLineNumber   = (String)searchParams.get("lineNumber");

    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, serchHeaderNumber);
    setWhereClauseParam(1, serchLineNumber);
  
    // SELECT�����s
    executeQuery();
  }
}