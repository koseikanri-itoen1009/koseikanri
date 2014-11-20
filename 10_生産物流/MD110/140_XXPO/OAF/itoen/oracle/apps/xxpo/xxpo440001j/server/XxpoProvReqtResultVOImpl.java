/*============================================================================
* �t�@�C���� : XxpoProvReqtResultVOImpl
* �T�v����   : �x���w���v�񌋉ʃr���[�I�u�W�F�N�g
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-05 1.0  ��r���     �V�K�쐬
* 2008-06-09 1.1  ��r���     �ύX�v��#42�Ή�
* 2009-02-16 1.2  ��r���     �{�ԏ�Q#469�Ή�
* 2009-03-13 1.3  �ѓc  ��     �{�ԏ�Q#1300�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �x���w���v�񌋉ʃr���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.3
 ***************************************************************************
 */
public class XxpoProvReqtResultVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvReqtResultVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param shParams - �����p�����[�^
   ****************************************************************************/
  public void initQuery(
    HashMap shParams
    )
  {
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
    ArrayList parameters = new ArrayList();             // �o�C���h�ϐ��ݒ�l
    int bindCount = 0;                                  // �o�C���h�ϐ��J�E���g

    // ������
    setWhereClauseParams(null);

    // ���������擾
    Number orderType    = (Number)shParams.get("orderType");    // �����敪
    String vendorCode   = (String)shParams.get("vendorCode");   // �����
    String shipToCode   = (String)shParams.get("shipToCode");   // �z����
    String reqNo        = (String)shParams.get("reqNo");        // �˗�No
    String shipToNo     = (String)shParams.get("shipToNo");     // �z��No
    String transStatus  = (String)shParams.get("transStatus");  // �X�e�[�^�X
    String notifStatus  = (String)shParams.get("notifStatus");  // �ʒm�X�e�[�^�X
    Date shipDateFrom   = (Date)shParams.get("shipDateFrom");   // �o�ɓ�From
    Date shipDateTo     = (Date)shParams.get("shipDateTo");     // �o�ɓ�To
    Date arvlDateFrom   = (Date)shParams.get("arvlDateFrom");   // ���ɓ�From
    Date arvlDateTo     = (Date)shParams.get("arvlDateTo");     // ���ɓ�To
    String reqDeptCode  = (String)shParams.get("reqDeptCode");  // �˗�����
    String instDeptCode = (String)shParams.get("instDeptCode"); // �w������
    String shipWhseCode = (String)shParams.get("shipWhseCode"); // �o�ɑq��  
    String exeType      = (String)shParams.get("exeType");      // �N���^�C�v  
    String baseReqNo    = (String)shParams.get("baseReqNo");    // ���˗�No
// 2009-03-13 H.Iida ADD START �{�ԏ�Q#1300
    String fixClass    = (String)shParams.get("fixClass");      // ���z�m��
// 2009-03-13 H.Iida ADD END
    
    // �N���^�C�v(�K�{)
    XxcmnUtility.andAppend(whereClause);
    whereClause.append("exe_type = :" + bindCount++);
    parameters.add(exeType);
    // �����敪�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(orderType))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("order_type_id = :" + bindCount++);
      // �����l���Z�b�g
      parameters.add(orderType);      
    }
    // ����悪���͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(vendorCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("vendor_code = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(vendorCode);      
    }
    // �z���悪���͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipToCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("ship_to_code = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(shipToCode);      
    }
    // �˗�No�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(reqNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("request_no = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(reqNo);      
    }
    // �z��No�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipToNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("ship_to_no = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(shipToNo);      
    }
    // �X�e�[�^�X�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(transStatus))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("trans_status = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(transStatus);      
    }
    // �ʒm�X�e�[�^�X�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(notifStatus))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("notif_status = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(notifStatus);      
    }
    // �o�ɓ�From�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("shipped_date >= :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(shipDateFrom);      
    }
    // �o�ɓ�To�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("shipped_date <= :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(shipDateTo);
    }
    // ���ɓ�From�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(arvlDateFrom))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("arrival_date >= :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(arvlDateFrom);      
    }
    // ���ɓ�To�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(arvlDateTo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("arrival_date <= :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(arvlDateTo);      
    }
    // �˗����������͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(reqDeptCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("req_dept_code = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(reqDeptCode);      
    }
    // �w�����������͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(instDeptCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("inst_dept_code = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(instDeptCode);      
    }
    // �o�ɑq�ɂ����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipWhseCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("ship_whse_code = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(shipWhseCode);      
    }
    // ���˗�No�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(baseReqNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append(" (request_no = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(baseReqNo);      
      // Where�吶��
      whereClause.append(" OR base_request_no = :" + bindCount++ + ") ");
      //�����l���Z�b�g
      parameters.add(baseReqNo);      
    }
// 2009-03-13 H.Iida ADD START �{�ԏ�Q#1300
    // ���z�w�肪���͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(fixClass))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where�吶��
      whereClause.append("fix_class = :" + bindCount++);
      //�����l���Z�b�g
      parameters.add(fixClass);      
    }
// 2009-03-13 H.Iida ADD END

    // ����������VO�ɃZ�b�g
    setWhereClause(whereClause.toString());

// 2009-02-16 v1.2 D.Nihei Add Start �{�ԏ�Q#469�Ή�
    // �q���g����ȉ��̏����̏ꍇ�g�p����B
    if (!XxcmnUtility.isBlankOrNull(transStatus)
      && XxcmnUtility.isBlankOrNull(vendorCode)
      && XxcmnUtility.isBlankOrNull(shipToCode)
      && XxcmnUtility.isBlankOrNull(shipWhseCode)
      && XxcmnUtility.isBlankOrNull(reqNo)
      && XxcmnUtility.isBlankOrNull(shipToNo)) 
    {
        setQueryOptimizerHint(" index(QRSLT.xoha xxwsh_oh_n29) ");
    } else
    {
        setQueryOptimizerHint(null);
    }
// 2009-02-16 v1.2 D.Nihei Add End

    // �o�C���h�l���ݒ肳��Ă����ꍇ
    if (bindCount > 0)
    {
      // �����l�z����擾
      Object[] params = new Object[bindCount];
      params = parameters.toArray();  
      // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
      setWhereClauseParams(params);
    }
    // �������s
    executeQuery();
  }
}