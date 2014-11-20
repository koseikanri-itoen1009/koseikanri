/*============================================================================
* �t�@�C���� : XxpoInspectLotSummaryVOImpl
* �T�v����   : �������b�g�������ʃr���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c���     �V�K�쐬
* 2008-05-09 1.1  �F�{ �a�Y      �����ύX�v��#28,41,43�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
// 20080509 add start kumamoto
import oracle.jbo.domain.Date;
// 20080509 add end kumamoto
/***************************************************************************
 * �������b�g�������ʃr���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �˒J�c ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoInspectLotSummaryVOImpl()
  {
  }

  /***************************************************************************
   * VO�̏��������s���܂��B
	 * @param HashMap    - ��������
   ***************************************************************************
   */
  public void initQuery(HashMap searchParams)
  {
    // WHERE��̏�����
    setWhereClauseParams(null);

    // �ϐ���`
    int bindCount = 0;                                  // �o�C���h�ϐ�
    List list = new ArrayList();                        // ���������l���i�[
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE����i�[

    // �����L�[�̎擾
    String vendorCode = (String)searchParams.get("vendorCode");
    String itemCode = (String)searchParams.get("itemCode");
    String lotNo = (String)searchParams.get("lotNo");
    String productFactory = (String)searchParams.get("productFactory");
    String productLotNo = (String)searchParams.get("productLotNo");
// 20080509 mod start kumamoto
//    oracle.jbo.domain.Date attribute1From 
//      = (oracle.jbo.domain.Date)searchParams.get("productDateFrom");
//    oracle.jbo.domain.Date attribute1To
//      = (oracle.jbo.domain.Date)searchParams.get("productDateTo");
//    oracle.jbo.domain.Date creationDateFrom
//      = (oracle.jbo.domain.Date)searchParams.get("creationDateFrom");
//    oracle.jbo.domain.Date creationDateTo
//      = (oracle.jbo.domain.Date)searchParams.get("creationDateTo");

    Date attribute1From = (Date)searchParams.get("productDateFrom");
    Date attribute1To = (Date)searchParams.get("productDateTo");
    Date creationDateFrom = (Date)searchParams.get("creationDateFrom");
    Date creationDateTo = (Date)searchParams.get("creationDateTo");
// 20080509 mod end kumamoto
    Number itemId = (Number)searchParams.get("itemId");
    Number qtInspectReqNo = (Number)searchParams.get("qtInspectReqNo");

    // *************************** //
    // *         �����쐬         * //
    // *************************** //
    // �����
    if (!XxcmnUtility.isBlankOrNull(vendorCode))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute8 LIKE :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" attribute8 LIKE :" + bindCount);
      }
      // �o�C���h�ϐ��̃J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(vendorCode);
    }

    // �i�ڂɒl�����͂���Ă����ꍇ�A�i��ID�����������ɒǉ�
    if (!XxcmnUtility.isBlankOrNull(itemId))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND item_id LIKE :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" item_id LIKE :" + bindCount);
      }
      // �o�C���h�ϐ��̃J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(itemId);
    }

    // ���b�g�ԍ�
    if (!XxcmnUtility.isBlankOrNull(lotNo))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND lot_no LIKE :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" lot_no LIKE :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(lotNo);
    }

    // �����H��
    if (!XxcmnUtility.isBlankOrNull(productFactory))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute20 LIKE :" + bindCount);
      // ��������1����
      } else
      {
        whereClause.append(" attribute20 LIKE :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(productFactory);
    }

    // �������b�g�ԍ�
    if (!XxcmnUtility.isBlankOrNull(productLotNo))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute21 LIKE :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" attribute21 LIKE :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(productLotNo);
    }

    // ������/�d����(��)
    if (!XxcmnUtility.isBlankOrNull(attribute1From))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute1 >= :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" attribute1 >= :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(attribute1From);
    }
    
    // ������/�d����(��)
    if (!XxcmnUtility.isBlankOrNull(attribute1To))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute1 <= :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" attribute1 <= :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(attribute1To);
    }

    // ���͓�(��)
    if (!XxcmnUtility.isBlankOrNull(creationDateFrom))
    {
      // ��������1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND trunc(creation_date) >= :" + bindCount);
      // ��������1����
      } else
      {
        whereClause.append(" trunc(creation_date) >= :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(creationDateFrom);
    }

    // ���͓�(��)
    if (!XxcmnUtility.isBlankOrNull(creationDateTo))
    {
      // ��������1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND trunc(creation_date) <= :" + bindCount);
      // ��������1����
      } else
      {
        whereClause.append(" trunc(creation_date) <= :" + bindCount);
      }
      // �o�C���h�ϐ����J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(creationDateTo);
    }

    // �����˗�No
    if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
    {
      // �ǉ�����1���ڈȍ~
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND qt_inspect_req_no LIKE :" + bindCount);
      // �ǉ�����1����
      } else
      {
        whereClause.append(" qt_inspect_req_no LIKE :" + bindCount);
      }
      // �o�C���h�ϐ��̃J�E���g
      bindCount ++;
      // �����L�[���Z�b�g
      list.add(qtInspectReqNo);
    }
    // ����������VO�ɃZ�b�g
    setWhereClause(whereClause.toString());

    // �o�C���h�ϐ��ɒl���ݒ肳�ꂽ�ꍇ
    if (bindCount > 0)
    {
      // �����l�z����擾
      Object[] params = new Object[bindCount];
      params = list.toArray();
      
      // SELECT�����s
      setWhereClauseParams(params);
      executeQuery();

    // �ݒ肳��Ȃ������ꍇ
    } else
    {
      return;
    }
  }
}